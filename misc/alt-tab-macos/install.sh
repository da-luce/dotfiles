#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PLIST_NAME="com.lwouis.alt-tab-macos.plist"
PLIST_PATH="$SCRIPT_DIR/$PLIST_NAME"

if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Error: plist file not found at $PLIST_PATH"
  exit 1
fi

echo "Importing preferences from $PLIST_PATH..."

defaults import com.lwouis.alt-tab-macos "$PLIST_PATH"

echo "Done."
