# Generic Flat-File Backup Script (PowerShell)

This is a user-configurable PowerShell script for backing up files (of any specified types) from a source folder to a backup folder. It logs changes, creates versioned zip archives, and keeps a history of changes.

## Supported File Types
- **Recommended:** Any text-based file type, including:
  - `.txt`, `.csv`, `.log`, `.ini`, `.conf`, `.cfg`
  - `.py`, `.js`, `.ts`, `.java`, `.c`, `.cpp`, `.sh`, `.ps1`
  - `.md`, `.rst`, `.adoc`
  - `.json`, `.xml`, `.yaml`, `.yml`, `.tsv`, `.html`, `.htm`
- **Not recommended:** Binary files (e.g., `.exe`, `.jpg`, `.png`, `.pdf`, `.docx`, `.xlsx`, `.zip`)
  - These can be copied/zipped, but change logging/diffing will not work and may cause errors.

## Overview
- **Incremental backup**: Only new or changed files (of user-specified types) are copied.
- **Change logging**: Logs added/removed lines for each file.
- **Versioned archives**: Creates timestamped zip archives of the backup folder (excluding the `versions` subfolder).
- **Script traceability**: Backs up the script itself for each run.
- **Retention**: Keeps only the most recent 20 zip archives.
- **Supports ignoring specific files by name**

## Features
- Cross-platform: Works on Windows and PowerShell Core (macOS/Linux)
- Easy to customize: Change file types, retention, or folder paths
- Heavily commented for clarity

## Requirements
- PowerShell 5.0+ (Windows) or PowerShell Core 7+ (macOS/Linux)
- No external dependencies

## Usage
1. Place your files in a folder (e.g., `C:\Source`).
2. Edit `backup.ps1` to set which file types/extensions to back up and which files to ignore:
   ```powershell
   $FileExtensions = @('.txt', '.csv', '.log')      # Back up .txt, .csv, and .log files
   $IgnoreFiles = @('ignoreme.txt', 'skip.csv')     # Ignore these files
   ```
3. Open PowerShell and run:
   ```powershell
   cd path\to\powershell-backup
   .\backup.ps1
   ```
   Or, for PowerShell Core on macOS/Linux:
   ```sh
   pwsh backup.ps1
   ```

## Customization
- **File types**: Change `$FileExtensions` in the script to specify which file types to back up (multiple extensions supported).
- **Ignored files**: Add file names to the `$IgnoreFiles` array to skip them during backup.
- **Retention**: Edit the `MaxZips` parameter in `Remove-OldZips`.
- **Folders**: Change the default `$SourceFolder` and `$BackupFolder` at the top of the script.

## Example Output
```
Copied: notes.txt
Copied: data.csv
Copied: log2024.log
Zipped files saved to C:\Backup\versions\backup_20240613_153000.zip
Change log saved to C:\Backup\versions\change_log.txt
```

## Troubleshooting
- Make sure you have permission to read/write the source and backup folders.
- If you see errors about file locks, close any programs using the files.
- On macOS/Linux, use PowerShell Core (`pwsh`).

## License
MIT License (add a LICENSE file if you wish)

---

**Contributions and suggestions welcome!** 