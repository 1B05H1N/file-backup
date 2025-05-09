#!/bin/bash
# Generic Backup Shell Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/../venv"

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Run the backup script
python "$SCRIPT_DIR/../python-backup/backup.py" 