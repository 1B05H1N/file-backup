#!/usr/bin/env bash
# Generic Flat-File Backup Script (Bash)
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
# - Multiple file extensions, ignore by name, max zips retention, script self-backup
#
# See README.md for usage instructions.

set -euo pipefail

# --- CONFIG LOADING ---
# Default config
SOURCE_FOLDER="./source"
BACKUP_FOLDER="./backup"
FILE_EXTENSIONS=(".txt")
IGNORE_FILES=()
IGNORE_PATTERNS=()
MAX_ZIPS=20

# Try to load config.yaml (requires yq) or config.json (requires jq)
CONFIG_DIR="$(dirname "$0")"
if [[ -f "$CONFIG_DIR/config.yaml" ]] && command -v yq >/dev/null 2>&1; then
    SOURCE_FOLDER="$(yq '.source_folder' "$CONFIG_DIR/config.yaml")"
    BACKUP_FOLDER="$(yq '.backup_folder' "$CONFIG_DIR/config.yaml")"
    FILE_EXTENSIONS=($(yq '.file_extensions[]' "$CONFIG_DIR/config.yaml"))
    IGNORE_FILES=($(yq '.ignore_files[]' "$CONFIG_DIR/config.yaml"))
    IGNORE_PATTERNS=($(yq '.ignore_patterns[]' "$CONFIG_DIR/config.yaml"))
    MAX_ZIPS="$(yq '.max_zips' "$CONFIG_DIR/config.yaml")"
elif [[ -f "$CONFIG_DIR/config.json" ]] && command -v jq >/dev/null 2>&1; then
    SOURCE_FOLDER="$(jq -r '.source_folder' "$CONFIG_DIR/config.json")"
    BACKUP_FOLDER="$(jq -r '.backup_folder' "$CONFIG_DIR/config.json")"
    FILE_EXTENSIONS=($(jq -r '.file_extensions[]' "$CONFIG_DIR/config.json"))
    IGNORE_FILES=($(jq -r '.ignore_files[]' "$CONFIG_DIR/config.json"))
    IGNORE_PATTERNS=($(jq -r '.ignore_patterns[]' "$CONFIG_DIR/config.json"))
    MAX_ZIPS="$(jq -r '.max_zips' "$CONFIG_DIR/config.json")"
fi

META_FOLDER="$BACKUP_FOLDER/versions"
LOG_FILE="$META_FOLDER/change_log.txt"
ZIP_FILE_NAME="$META_FOLDER/backup_$(date +%Y%m%d_%H%M%S).zip"

# --- UTILS ---
backup_script() {
    mkdir -p "$1"
    cp "$0" "$1/backup_script_$(date +%Y%m%d_%H%M%S).sh"
}

is_binary_file() {
    # Returns 0 if binary, 1 if text
    file "$1" | grep -qE 'binary|executable|image|audio|video|archive|compressed' && return 0 || return 1
}

should_ignore() {
    local fname="$1"
    for ign in "${IGNORE_FILES[@]}"; do
        [[ "$fname" == "$ign" ]] && return 0
    done
    for pat in "${IGNORE_PATTERNS[@]}"; do
        [[ "$fname" == $pat ]] && return 0
    done
    return 1
}

compare_files() {
    # Only for text files; returns diff summary
    local src="$1" dst="$2"
    if [[ ! -f "$dst" ]]; then return 1; fi
    diff_out=$(diff -u "$dst" "$src" || true)
    if [[ -n "$diff_out" ]]; then
        echo "$diff_out"
        return 0
    fi
    return 1
}

remove_old_zips() {
    local zip_dir="$1" max_zips="$2"
    ls -1t "$zip_dir"/*.zip 2>/dev/null | tail -n +$((max_zips+1)) | xargs -r rm --
}

# --- MAIN BACKUP LOGIC ---
mkdir -p "$BACKUP_FOLDER" "$META_FOLDER"
backup_script "$META_FOLDER"

find "$SOURCE_FOLDER" -type f | while read -r src_file; do
    fname="$(basename "$src_file")"
    ext=".${fname##*.}"
    # Check extension
    match_ext=false
    for e in "${FILE_EXTENSIONS[@]}"; do
        [[ "$ext" == "$e" ]] && match_ext=true && break
    done
    $match_ext || continue
    # Ignore by name/pattern
    should_ignore "$fname" && continue
    # Compute destination path
    rel_path="${src_file#$SOURCE_FOLDER/}"
    dst_file="$BACKUP_FOLDER/$rel_path"
    dst_dir="$(dirname "$dst_file")"
    mkdir -p "$dst_dir"
    # Binary detection
    if is_binary_file "$src_file"; then
        if [[ ! -f "$dst_file" ]] || ! cmp -s "$src_file" "$dst_file"; then
            cp "$src_file" "$dst_file"
            echo "Copied (binary): $rel_path"
        fi
        continue
    fi
    # Text file: diff and log
    if [[ ! -f "$dst_file" ]]; then
        cp "$src_file" "$dst_file"
        echo "Copied: $rel_path"
    else
        changes=$(compare_files "$src_file" "$dst_file")
        if [[ $? -eq 0 ]]; then
            cp "$src_file" "$dst_file"
            echo "Copied: $rel_path"
            echo -e "Changes in $rel_path on $(date '+%Y-%m-%d %H:%M:%S')\n$changes\n" >> "$LOG_FILE"
        fi
    fi

done

# Zip backup (excluding META_FOLDER)
(cd "$BACKUP_FOLDER" && zip -r "$ZIP_FILE_NAME" . -x "versions/*")
echo "Zipped files saved to $ZIP_FILE_NAME"

# Retention
remove_old_zips "$META_FOLDER" "$MAX_ZIPS"
echo "Change log saved to $LOG_FILE" 