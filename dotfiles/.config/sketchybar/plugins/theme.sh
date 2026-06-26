#!/usr/bin/env bash
# Reload the bar only when the system appearance actually flips,
# so colors.sh re-evaluates light vs dark. No reload = no flicker.

STATE_FILE="/tmp/sketchybar_appearance"

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  CURRENT="dark"
else
  CURRENT="light"
fi

[ "$CURRENT" = "$(cat "$STATE_FILE" 2>/dev/null)" ] && exit 0

echo "$CURRENT" >"$STATE_FILE"
sketchybar --reload
