# Generic Flat-File Backup Script (Python)

This is a user-configurable Python script for backing up files (of any specified types) from a source folder to a backup folder. It logs changes, creates versioned zip archives, and keeps a history of changes.

## Supported File Types
- **Recommended:** Any text-based file type, including:
  - `.txt`, `.csv`, `.log`, `.ini`, `.conf`, `.cfg`
  - `.py`, `.js`, `.ts`, `.java`, `.c`, `.cpp`, `.sh`, `.ps1`
  - `.md`, `.rst`, `.adoc`
  - `.json`, `.xml`, `.yaml`, `.yml`, `.tsv`, `.html`, `.htm`
- **Not recommended:** Binary files (e.g., `.exe`, `.jpg`, `.png`, `.pdf`, `.docx`, `.xlsx`, `.zip`)
  - These can be copied/zipped, but change logging/diffing will not work and may cause errors.

## Features
- Copies only changed or new files (of any user-specified types, e.g., `.txt`, `.csv`, `.log`) from the source to the backup folder
- Logs added/removed lines for each file
- Creates timestamped zip archives of the backup folder (excluding the `versions` subfolder)
- Keeps only the most recent 20 zip archives
- Backs up the script itself for traceability
- **Supports ignoring specific files by name**

## Requirements
- Python 3.8 or newer
- No external dependencies (standard library only)

## Usage
1. Place your files in a folder (e.g., `./source`).
2. Edit `backup.py` to set which file types/extensions to back up and which files to ignore:
   ```python
   FILE_EXTENSIONS = [".txt", ".csv", ".log"]  # Back up .txt, .csv, and .log files
   IGNORE_FILES = ["ignoreme.txt", "skip.csv"]   # Ignore these files
   ```
3. (Optional) Set up a Python virtual environment and install requirements:
   ```sh
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
4. Run the script:
   ```sh
   python backup.py
   ```
5. Or use the provided shell wrapper:
   ```sh
   ./run-backup.sh
   ```

## Customization
- Change the `FILE_EXTENSIONS` list in the script to specify which file types to back up (multiple extensions supported).
- Add file names to the `IGNORE_FILES` list to skip them during backup.
- Adjust the number of zip archives to keep by editing the `max_zips` parameter.

## Notes
- The script is heavily commented for clarity.
- Make sure source and backup folders are not the same. 