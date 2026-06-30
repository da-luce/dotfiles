#!/usr/bin/env sh
# Directional window focus that skips floating windows (e.g. Chrome
# Picture-in-Picture), which otherwise trap focus and block navigation.
# Re-focuses in the same direction until it lands on a managed window; falls
# back to focusing the adjacent display when there's none that way.
# $1 = west|east|north|south

dir="$1"
i=0
while [ "$i" -lt 6 ]; do
  i=$((i + 1))
  if ! yabai -m window --focus "$dir" 2>/dev/null; then
    yabai -m display --focus "$dir" 2>/dev/null
    exit 0
  fi
  # Stop once focus lands on a tiled (managed) window.
  yabai -m query --windows --window 2>/dev/null | grep -qE '"is-floating": *false' && exit 0
done
