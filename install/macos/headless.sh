#!/usr/bin/env bash
# Headless macOS settings

set -euo pipefail

[ "$(uname -s)" = "Darwin" ] || { echo "error: macOS only" >&2; exit 1; }

if ! sudo -v >/dev/null 2>&1; then
  echo "error: this script needs sudo. Run it from an interactive shell" >&2
  exit 1
fi

echo "==> Power"
# undo: sudo pmset -a sleep 1 displaysleep 10 womp 0
sudo pmset -a sleep 0            # system never sleeps
sudo pmset -a displaysleep 0     # no display to blank anyway
sudo pmset -a womp 1             # wake for network access
# Restart after a power cut. `pmset autorestart` is the desktop-only equivalent
# of systemsetup -setrestartpowerfailure, and unlike systemsetup it needs no
# Full Disk Access. Laptops do not expose the key at all.
sudo pmset -a autorestart 1 2>/dev/null \
  || echo " !  autorestart not supported on this Mac (laptops do not have it)"
# undo: sudo pmset -a autorestart 0

echo "==> Current power settings"
pmset -g custom | sed -n '1,12p'
