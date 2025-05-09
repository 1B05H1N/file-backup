# Generic Flat-File Backup Script (PowerShell)
#
# Supports any text-based file type, including:
#   .txt, .csv, .log, .ini, .conf, .cfg
#   .py, .js, .ts, .java, .c, .cpp, .sh, .ps1
#   .md, .rst, .adoc
#   .json, .xml, .yaml, .yml, .tsv, .html, .htm
# Binary files (e.g., .exe, .jpg, .png, .pdf, .docx, .xlsx, .zip) can be copied/zipped,
# but change logging/diffing will not work and may cause errors.
#
# Features:
# - Recursive subfolder backup (preserves structure)
# - Automatic binary file detection (skips diff/logging for binaries)
# - Pattern-based ignore (wildcards, e.g., *.bak, temp*, *~)
# - Config file support (YAML or JSON)
#
# See README.md for usage instructions.

param (
    [string]$SourceFolder = "C:\Source",   # Folder containing files to back up
    [string]$BackupFolder = "C:\Backup"     # Folder where backups will be stored
)

# Specify which file extensions to back up (e.g., @('.txt', '.csv', '.log'))
$FileExtensions = @('.txt')  # Change this list as needed
# Specify file names to ignore (e.g., @('ignoreme.txt', 'skip.csv'))
$IgnoreFiles = @()           # Add file names to ignore here
# Specify wildcard patterns to ignore (e.g., @('*.bak', 'temp*', '*~'))
$IgnorePatterns = @()        # Add wildcard patterns to ignore here
$MaxZips = 20

# Try to load config from YAML or JSON if present
function Load-Config {
    $config = @{
        SourceFolder = $SourceFolder
        BackupFolder = $BackupFolder
        FileExtensions = $FileExtensions
        IgnoreFiles = $IgnoreFiles
        IgnorePatterns = $IgnorePatterns
        MaxZips = $MaxZips
    }
    $yamlPath = Join-Path $PSScriptRoot 'config.yaml'
    $jsonPath = Join-Path $PSScriptRoot 'config.json'
    if (Test-Path $yamlPath) {
        try {
            Import-Module powershell-yaml -ErrorAction Stop
            $userConfig = ConvertFrom-Yaml (Get-Content $yamlPath -Raw)
            foreach ($key in $userConfig.PSObject.Properties.Name) {
                $config[$key] = $userConfig[$key]
            }
        } catch {
            Write-Output "Could not load YAML config: $_"
        }
    } elseif (Test-Path $jsonPath) {
        try {
            $userConfig = Get-Content $jsonPath | ConvertFrom-Json
            foreach ($key in $userConfig.PSObject.Properties.Name) {
                $config[$key] = $userConfig[$key]
            }
        } catch {
            Write-Output "Could not load JSON config: $_"
        }
    }
    return $config
}

# Heuristic: Check if file is binary. Returns $true if binary, $false if text.
function Is-BinaryFile {
    param([string]$Path)
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        # Check for null bytes
        if ($bytes -contains 0) { return $true }
        # Try to guess by extension (common text types)
        $ext = [System.IO.Path]::GetExtension($Path)
        $textExts = @('.txt','.csv','.log','.ini','.conf','.cfg','.py','.js','.ts','.java','.c','.cpp','.sh','.ps1','.md','.rst','.adoc','.json','.xml','.yaml','.yml','.tsv','.html','.htm')
        if ($textExts -contains $ext) { return $false }
    } catch { return $true }
    return $false
}

# Return $true if file name matches any ignore file or pattern
function Should-Ignore {
    param(
        [string]$FileName,
        [array]$IgnoreFiles,
        [array]$IgnorePatterns
    )
    if ($IgnoreFiles -contains $FileName) { return $true }
    foreach ($pat in $IgnorePatterns) {
        if ($FileName -like $pat) { return $true }
    }
    return $false
}

# Backs up this script to the versions folder for traceability
function Backup-Script {
    param(
        [string]$BackupMetaFolder
    )
    $scriptPath = $MyInvocation.MyCommand.Path
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "BackupScript_$timestamp.ps1"
    $backupPath = Join-Path $BackupMetaFolder $backupName
    try {
        Copy-Item -Path $scriptPath -Destination $backupPath -Force
        Write-Output "Script backed up to $backupPath"
    } catch {
        Write-Output "Error backing up script: $_"
    }
}

# Appends change details to the log file
function Log-Changes {
    param(
        [string]$FileName,
        [string]$Changes,
        [string]$LogFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "Changes in $FileName on $timestamp"
    Add-Content -Path $LogFile -Value $entry -Encoding UTF8
    Add-Content -Path $LogFile -Value $Changes -Encoding UTF8
    Add-Content -Path $LogFile -Value "" -Encoding UTF8
}

# Compares the content of the source file and destination file
# Returns a string describing added and removed lines, or an empty string if no changes
function Compare-Files {
    param(
        [string]$SourceFile,
        [string]$DestFile
    )
    if (-not (Test-Path $DestFile)) {
        return $null
    }
    $sourceContent = Get-Content $SourceFile -Encoding UTF8
    $destContent   = Get-Content $DestFile -Encoding UTF8
    $added = $sourceContent | Where-Object { $destContent -notcontains $_ }
    $removed = $destContent | Where-Object { $sourceContent -notcontains $_ }
    $changes = @()
    if ($added.Count -gt 0) {
        $changes += "Added lines:"; $changes += $added
    }
    if ($removed.Count -gt 0) {
        $changes += "Removed lines:"; $changes += $removed
    }
    if ($changes.Count -gt 0) {
        return $changes -join "`n"
    }
    return ""
}

# Removes old zip files in the given folder, keeping only the most recent $MaxZips
function Remove-OldZips {
    param(
        [string]$ZipFolder,
        [int]$MaxZips = 20
    )
    $zips = Get-ChildItem -Path $ZipFolder -Filter "*.zip" -File | Sort-Object LastWriteTime -Descending
    if ($zips.Count -gt $MaxZips) {
        $oldZips = $zips | Select-Object -Skip $MaxZips
        foreach ($oldZip in $oldZips) {
            try {
                Remove-Item $oldZip.FullName -Force
            } catch {
                Write-Output "Error deleting file $($oldZip.FullName): $_"
            }
        }
    }
}

# Main function: recursively copies updated files, logs changes, creates a zip archive, and cleans up old zips
function Copy-AndZip-Files {
    param(
        [hashtable]$Config
    )
    $SourceFolder = $Config.SourceFolder
    $BackupFolder = $Config.BackupFolder
    $FileExtensions = $Config.FileExtensions
    $IgnoreFiles = $Config.IgnoreFiles
    $IgnorePatterns = $Config.IgnorePatterns
    $MaxZips = $Config.MaxZips
    # Ensure the backup folder exists
    if (-not (Test-Path $BackupFolder)) {
        New-Item -Path $BackupFolder -ItemType Directory | Out-Null
    }
    # Create a subfolder (versions) for logs, script backups, and zip files
    $metaFolder = Join-Path $BackupFolder "versions"
    if (-not (Test-Path $metaFolder)) {
        New-Item -Path $metaFolder -ItemType Directory | Out-Null
    }
    # Backup this script for traceability
    Backup-Script -BackupMetaFolder $metaFolder
    $logFile = Join-Path $metaFolder "change_log.txt"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipFileName = Join-Path $metaFolder "backup_$timestamp.zip"
    # Recursively process all files
    Get-ChildItem -Path $SourceFolder -Recurse -File | ForEach-Object {
        $fileName = $_.Name
        $sourceFile = $_.FullName
        $relPath = Resolve-Path -Path $sourceFile -Relative | ForEach-Object { $_.Replace($SourceFolder, '').TrimStart('\/') }
        $relPath = if ($relPath) { $relPath } else { $fileName }
        $destFile = Join-Path $BackupFolder $relPath
        $destDir = Split-Path $destFile -Parent
        if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory | Out-Null }
        if (-not ($FileExtensions | Where-Object { $fileName.ToLower().EndsWith($_.ToLower()) })) { return }
        if (Should-Ignore $fileName $IgnoreFiles $IgnorePatterns) { return }
        $isBinary = Is-BinaryFile $sourceFile
        $changes = $null
        if (-not $isBinary) {
            $changes = Compare-Files -SourceFile $sourceFile -DestFile $destFile
        }
        if ($changes -or -not (Test-Path $destFile)) {
            Copy-Item -Path $sourceFile -Destination $destFile -Force
            Write-Output "Copied: $relPath"
            if ($changes -and -not $isBinary) {
                Log-Changes -FileName $relPath -Changes $changes -LogFile $logFile
            } elseif ($isBinary) {
                Write-Output "(Binary file, skipped diff/log): $relPath"
            }
        }
    }
    # Create a zip archive of all files in the backup folder (excluding the meta folder and its contents)
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $filesToZip = Get-ChildItem -Path $BackupFolder -Recurse -File | Where-Object { $_.FullName -notlike "$metaFolder*" }
        if ($filesToZip.Count -gt 0) {
            $zip = [System.IO.Compression.ZipFile]::Open($zipFileName, 'Create')
            foreach ($file in $filesToZip) {
                $rel = $file.FullName.Substring($BackupFolder.Length).TrimStart('\/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $rel)
            }
            $zip.Dispose()
            Write-Output "Zipped files saved to $zipFileName"
        } else {
            Write-Output "No files to zip in $BackupFolder"
        }
    } catch {
        Write-Output "Error creating zip file: $_"
    }
    # Remove old zip archives
    Remove-OldZips -ZipFolder $metaFolder -MaxZips $MaxZips
    Write-Output "Change log saved to $logFile"
}

# MAIN
$config = Load-Config
if ($config.SourceFolder -eq $config.BackupFolder) {
    Write-Error "Source and backup folders must not be the same."
    exit 1
}
Copy-AndZip-Files -Config $config 