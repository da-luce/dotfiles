#!/usr/bin/env bash
# Install the Bitwarden Secrets Manager CLI (bws) into ~/.local/bin.
# Homebrew has no formula for it, so pull the signed release binary instead.

set -euo pipefail

VERSION="2.1.0"
DEST="$HOME/.local/bin"
BASE="https://github.com/bitwarden/sdk-sm/releases/download/bws-v$VERSION"
ARCHIVE="bws-macos-universal-$VERSION.zip"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: macOS only" >&2
  exit 1
fi

if [ -x "$DEST/bws" ] && "$DEST/bws" --version 2>/dev/null | grep -q "$VERSION"; then
  echo "    bws $VERSION already installed"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/$ARCHIVE" "$BASE/$ARCHIVE"
curl -fsSL -o "$tmp/checksums.txt" "$BASE/bws-sha256-checksums-$VERSION.txt"

expected=$(awk -v f="$ARCHIVE" '$2 == f || $2 == "*"f { print $1 }' "$tmp/checksums.txt")
actual=$(shasum -a 256 "$tmp/$ARCHIVE" | awk '{print $1}')
if [ -z "$expected" ]; then
  echo "error: no checksum published for $ARCHIVE" >&2
  exit 1
fi
if [ "$expected" != "$actual" ]; then
  echo "error: checksum mismatch for $ARCHIVE" >&2
  exit 1
fi

mkdir -p "$DEST"
unzip -oq "$tmp/$ARCHIVE" -d "$tmp"
install -m 755 "$tmp/bws" "$DEST/bws"
echo "    installed $("$DEST/bws" --version)"
