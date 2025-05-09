# Flat-File Backup

A cross-platform, highly configurable toolkit for backing up any flat/text file type. Includes robust, feature-rich backup scripts in **Python**, **PowerShell**, and **Bash**—all with recursive subfolder support, pattern-based ignore, binary detection, and YAML/JSON config.

---

## Features
- **Recursive subfolder backup** (preserves directory structure)
- **Automatic binary file detection** (skips diff/logging for binaries)
- **Pattern-based ignore** (wildcards, e.g., `*.bak`, `temp*`, `*~`)
- **Config file support** (`config.yaml` or `config.json`)
- **Multiple file extensions** (back up any text-based file type)
- **Ignore by name or pattern**
- **Retention policy** (keep only the most recent N zip archives)
- **Script self-backup** (for traceability)
- **Well-commented, open source, and easy to extend**

---

## Supported Platforms
- **Python** (3.8+)
- **PowerShell** (5.0+ or PowerShell Core 7+)
- **Bash** (4+)

---

## Supported File Types
- **Recommended:** Any text-based file type, including:
  - `.txt`, `.csv`, `.log`, `.ini`, `.conf`, `.cfg`
  - `.py`, `.js`, `.ts`, `.java`, `.c`, `.cpp`, `.sh`, `.ps1`
  - `.md`, `.rst`, `.adoc`
  - `.json`, `.xml`, `.yaml`, `.yml`, `.tsv`, `.html`, `.htm`
- **Not recommended:** Binary files (e.g., `.exe`, `.jpg`, `.png`, `.pdf`, `.docx`, `.xlsx`, `.zip`)
  - These can be copied/zipped, but change logging/diffing will not work and may cause errors.

---

## Table of Contents
- [Python Backup](./python-backup/README.md)
- [PowerShell Backup](./powershell-backup/README.md)
- [Bash Backup](./bash-backup/README.md)

---

## Quick Start
1. Choose your preferred language folder:
   - [python-backup/](./python-backup/)
   - [powershell-backup/](./powershell-backup/)
   - [bash-backup/](./bash-backup/)
2. Read the language-specific README for setup and usage.
3. (Optional) Copy and edit the provided `config.yaml` or `config.json` to customize your backup.
4. Run the script!

---

## License
MIT License (see each script folder for details)

---

**Contributions and suggestions welcome!** 
