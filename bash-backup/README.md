# Generic Flat-File Backup Script (Bash)

This is a user-configurable Bash script for backing up files (of any specified types) from a source folder to a backup folder. It logs changes, creates versioned zip archives, and keeps a history of changes.

## Supported File Types
- **Recommended:** Any text-based file type, including:
  - `.txt`, `.csv`, `.log`, `.ini`, `.conf`, `.cfg`
  - `.py`, `.js`, `.ts`, `.java`, `.c`, `.cpp`, `.sh`, `.ps1`
  - `.md`, `.rst`, `.adoc`
  - `.json`, `.xml`, `.yaml`, `.yml`, `.tsv`, `.html`, `.htm`
- **Not recommended:** Binary files (e.g., `.exe`, `.jpg`, `.png`, `.pdf`, `.docx`, `.xlsx`, `.zip`)
  - These can be copied/zipped, but change logging/diffing will not work and may cause errors.

## Features
- Recursive subfolder backup (preserves structure)
- Automatic binary file detection (skips diff/logging for binaries)
- Pattern-based ignore (wildcards, e.g., `*.bak`, `temp*`, `*~`)
- Config file support (`config.yaml` with yq, or `config.json` with jq)
- Multiple file extensions, ignore by name, max zips retention, script self-backup

## Requirements
- Bash 4+
- `zip`, `diff`, `file`, `find`, `cmp`, `yq` (for YAML config), `jq` (for JSON config)

## Usage
1. Place your files in a folder (e.g., `./source`).
2. Edit `backup.sh` or use a config file (`config.yaml` or `config.json`) in the same folder:
   ```yaml
   # config.yaml example
   source_folder: ./source
   backup_folder: ./backup
   file_extensions:
     - .txt
     - .csv
     - .log
   ignore_files:
     - ignoreme.txt
     - skip.csv
   ignore_patterns:
     - '*.bak'
     - 'temp*'
     - '*~'
   max_zips: 20
   ```
3. Run the script:
   ```sh
   bash backup.sh
   ```

## Customization
- Change the `FILE_EXTENSIONS` array or config to specify which file types to back up (multiple extensions supported).
- Add file names to the `IGNORE_FILES` array or config to skip them during backup.
- Add patterns to `IGNORE_PATTERNS` for wildcard-based ignore.
- Adjust the number of zip archives to keep by editing the `MAX_ZIPS` variable or config.

## Notes
- The script is heavily commented for clarity.
- Make sure source and backup folders are not the same.
- For YAML config, install [yq](https://github.com/mikefarah/yq); for JSON config, install [jq](https://stedolan.github.io/jq/). 