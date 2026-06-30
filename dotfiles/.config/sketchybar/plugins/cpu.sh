#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

# "CPU usage: 4.63% user, 11.22% sys, 84.13% idle" -> idle is the 2nd-to-last field
IDLE=$(top -l1 -n0 | awk '/CPU usage/ {gsub("%","",$(NF-1)); print $(NF-1)}')
USAGE=$(awk -v idle="${IDLE:-100}" 'BEGIN { printf "%d", 100 - idle }')

if [ "$USAGE" -ge 80 ]; then
  COLOR=$RED;    ICON="󰓅"   # speedometer (full)
elif [ "$USAGE" -ge 50 ]; then
  COLOR=$YELLOW; ICON="󰾅"   # speedometer-medium
else
  COLOR=$GREEN;  ICON="󰾆"   # speedometer-slow
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${USAGE}%"
