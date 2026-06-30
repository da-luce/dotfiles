#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

STATUS=$(ifconfig en0 2>/dev/null | awk '/status:/ {print $2}')

if [ "$STATUS" = "active" ]; then
  SSID=$(ipconfig getsummary en0 2>/dev/null | awk -F': ' '/ SSID :/ {print $2; exit}')
  # macOS 14.4+ redacts the SSID without Location Services permission.
  if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
    SSID="Wi-Fi"
  fi
  sketchybar --set "$NAME" icon="󰖩" icon.color="$CYAN" label="$SSID"
else
  sketchybar --set "$NAME" icon="󰖪" icon.color="$GREY" label="Off"
fi
