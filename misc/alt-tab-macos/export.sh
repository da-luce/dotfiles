#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PLIST_NAME="com.lwouis.alt-tab-macos.plist"
PLIST_PATH="$SCRIPT_DIR/$PLIST_NAME"

echo "Exporting preferences to $PLIST_PATH..."

defaults export com.lwouis.alt-tab-macos - > "$PLIST_PATH"

echo "Done."
