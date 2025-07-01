#!/usr/bin/env bash
set -euo pipefail

# Resolve this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory for Rectangle config
TARGET_DIR="$HOME/Library/Application Support/Rectangle"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

echo "Stowing RectangleConfig.json to: $TARGET_DIR"

# Run stow from the current script dir into the target
stow -v -d "$SCRIPT_DIR" -t "$TARGET_DIR" .
