# Generic Flat-File Backup Script (Python)
#
# Supports any text-based file type, including:
#   .txt, .csv, .log, .ini, .conf, .cfg
#   .py, .js, .ts, .java, .c, .cpp, .sh, .ps1
#   .md, .rst, .adoc
#   .json, .xml, .yaml, .yml, .tsv, .html, .htm
# Binary files (e.g., .exe, .jpg, .png, .pdf, .docx, .xlsx, .zip) can be copied/zipped,
# but change logging/diffing will not work and may cause errors.
#
# This script copies changed or new files (of user-specified types) from a source folder to a backup folder.
# It logs the changes, creates timestamped zip archives, and keeps a history of changes.
#
# Features:
# - Recursive subfolder backup (preserves structure)
# - Automatic binary file detection (skips diff/logging for binaries)
# - Pattern-based ignore (wildcards, e.g., *.bak, temp*, *~)
# - Config file support (YAML or JSON)
#
# See README.md for usage instructions.

import os
import shutil
import zipfile
from datetime import datetime
import sys
import fnmatch
import mimetypes

# Try to import PyYAML for YAML config support
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
import json

def load_config():
    """
    Load config from config.yaml (if PyYAML is available), else config.json, else use defaults.
    Returns a dict with keys: source_folder, backup_folder, file_extensions, ignore_files, ignore_patterns, max_zips
    """
    config = {
        'source_folder': os.path.abspath('./source'),
        'backup_folder': os.path.abspath('./backup'),
        'file_extensions': ['.txt'],
        'ignore_files': [],
        'ignore_patterns': [],
        'max_zips': 20
    }
    if YAML_AVAILABLE and os.path.exists('config.yaml'):
        with open('config.yaml', 'r') as f:
            user_config = yaml.safe_load(f)
            if user_config:
                config.update(user_config)
    elif os.path.exists('config.json'):
        with open('config.json', 'r') as f:
            user_config = json.load(f)
            if user_config:
                config.update(user_config)
    return config

def is_binary_file(filepath):
    """
    Heuristic: Check if file is binary. Returns True if binary, False if text.
    """
    # Try mimetypes first
    mime, _ = mimetypes.guess_type(filepath)
    if mime and not mime.startswith('text'):
        return True
    # Fallback: check for null bytes
    try:
        with open(filepath, 'rb') as f:
            chunk = f.read(1024)
            if b'\0' in chunk:
                return True
    except Exception:
        return True  # treat unreadable files as binary
    return False

def backup_script(script_path, backup_folder):
    """
    Backup the current script to the backup_folder with a timestamp.
    This helps keep a record of the script version used for each backup.
    """
    if not os.path.exists(backup_folder):
        os.makedirs(backup_folder)
    backup_name = f"backup_script_{datetime.now().strftime('%Y%m%d_%H%M%S')}.py"
    backup_path = os.path.join(backup_folder, backup_name)
    try:
        shutil.copy2(script_path, backup_path)
        print(f"Script backed up to {backup_path}")
    except Exception as e:
        print(f"Error backing up script: {e}")

def log_changes(file_name, changes, log_file):
    """
    Append detailed information about changes to the log file.
    Each entry includes the file name, timestamp, and the specific changes.
    """
    with open(log_file, 'a', encoding='utf-8') as log:
        log.write(f"Changes in {file_name} on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        log.write(f"{changes}\n\n")

def compare_files(source_file, dest_file):
    """
    Compare the content of source and destination files.
    Returns a string describing added and removed lines, or an empty string if no changes.
    """
    if not os.path.exists(dest_file):
        return None
    with open(source_file, 'r', encoding='utf-8') as src, open(dest_file, 'r', encoding='utf-8') as dest:
        source_content = src.readlines()
        dest_content = dest.readlines()
    added = [line.strip() for line in source_content if line not in dest_content]
    removed = [line.strip() for line in dest_content if line not in source_content]
    changes = []
    if added:
        changes.append('Added lines:')
        changes.extend(added)
    if removed:
        changes.append('Removed lines:')
        changes.extend(removed)
    return '\n'.join(changes) if changes else ''

def remove_old_zips(zip_folder, max_zips=20):
    """
    Remove old zip files, keeping only the most recent ones (default: 20).
    This helps manage disk space in the backup folder.
    """
    zips = [os.path.join(zip_folder, f) for f in os.listdir(zip_folder) if f.endswith('.zip')]
    zips.sort(key=os.path.getmtime, reverse=True)
    for old_zip in zips[max_zips:]:
        try:
            os.remove(old_zip)
        except OSError as e:
            print(f"Error deleting file {old_zip}: {e}")

def should_ignore(file_name, ignore_files, ignore_patterns):
    """
    Return True if file_name matches any ignore file or pattern.
    """
    if file_name in ignore_files:
        return True
    for pat in ignore_patterns:
        if fnmatch.fnmatch(file_name, pat):
            return True
    return False

def copy_and_zip_files(config):
    """
    Copy changed files of specified types from source to backup, log changes, and zip the backup folder.
    - Recursively processes all subfolders, preserving structure.
    - Only files with extensions in config['file_extensions'] are processed.
    - Files in config['ignore_files'] or matching config['ignore_patterns'] are skipped.
    - Binary files are copied/zipped but not diffed/logged.
    - A 'versions' subfolder is used for logs, script backups, and zip archives.
    - The script itself is backed up for traceability.
    - Only the most recent config['max_zips'] zip archives are kept.
    """
    source_folder = config['source_folder']
    backup_folder = config['backup_folder']
    meta_folder = os.path.join(backup_folder, "versions")
    if not os.path.exists(backup_folder):
        os.makedirs(backup_folder)
    if not os.path.exists(meta_folder):
        os.makedirs(meta_folder)
    # Backup this script for traceability
    backup_script(os.path.abspath(sys.argv[0]), meta_folder)
    log_file = os.path.join(meta_folder, "change_log.txt")
    zip_file_name = os.path.join(meta_folder, f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip")
    for root, dirs, files in os.walk(source_folder):
        rel_dir = os.path.relpath(root, source_folder)
        for file_name in files:
            if not any(file_name.endswith(ext) for ext in config['file_extensions']):
                continue
            if should_ignore(file_name, config['ignore_files'], config['ignore_patterns']):
                continue
            source_file = os.path.join(root, file_name)
            rel_path = os.path.normpath(os.path.join(rel_dir, file_name)) if rel_dir != '.' else file_name
            dest_file = os.path.join(backup_folder, rel_path)
            dest_dir = os.path.dirname(dest_file)
            if not os.path.exists(dest_dir):
                os.makedirs(dest_dir)
            try:
                is_binary = is_binary_file(source_file)
                changes = None
                if not is_binary:
                    changes = compare_files(source_file, dest_file)
                if changes or not os.path.exists(dest_file):
                    shutil.copy2(source_file, dest_file)
                    print(f"Copied: {rel_path}")
                    if changes and not is_binary:
                        log_changes(rel_path, changes, log_file)
                    elif is_binary:
                        print(f"(Binary file, skipped diff/log): {rel_path}")
            except Exception as e:
                print(f"Error processing file {rel_path}: {e}")
    # Create a zip archive of all files in the backup folder (excluding the meta folder)
    try:
        with zipfile.ZipFile(zip_file_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(backup_folder):
                if os.path.abspath(root) == os.path.abspath(meta_folder):
                    continue
                for file_name in files:
                    file_path = os.path.join(root, file_name)
                    arcname = os.path.relpath(file_path, backup_folder)
                    zipf.write(file_path, arcname=arcname)
        print(f"Zipped files saved to {zip_file_name}")
    except Exception as e:
        print(f"Error creating zip file: {e}")
    # Remove old zip archives
    remove_old_zips(meta_folder, max_zips=config['max_zips'])
    print(f"Change log saved to {log_file}")

if __name__ == "__main__":
    config = load_config()
    if config['source_folder'] == config['backup_folder']:
        print("Source and backup folders must not be the same.")
        sys.exit(1)
    copy_and_zip_files(config)