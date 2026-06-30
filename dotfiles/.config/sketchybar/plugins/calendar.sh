#!/usr/bin/env bash
# Next/active meeting via the EventKit helper (skips events you've declined).
# Helper prints "<start_epoch>|<end_epoch>|<title>" or nothing.
# Writes the mode (+ today's start/end epochs) to a state file for calendar_flash.sh:
#   today <start_epoch> <end_epoch>   |   tomorrow   |   chill

source "$HOME/.config/sketchybar/colors.sh"

HELPER="$HOME/.config/sketchybar/bin/next_meeting"
STATE=/tmp/sketchybar_next_meeting

out=$("$HELPER" 2>/dev/null)
rc=$?

# Calendar access not granted -> show a hint instead of silently lying
if [ "$rc" = "2" ]; then
  echo "chill" >"$STATE"
  sketchybar --set "$NAME" drawing=on icon="󰃭" label="grant Calendar access"
  exit 0
fi

# No qualifying (non-declined) event in the window -> chill / palm tree
if [ -z "$out" ]; then
  echo "chill" >"$STATE"
  sketchybar --set "$NAME" drawing=on label=""
  exit 0
fi

start=${out%%|*}
rest=${out#*|}
end=${rest%%|*}
title=${rest#*|}

[ "${#title}" -gt 28 ] && title="${title:0:27}…"

start_hm=$(date -r "$start" +%H:%M 2>/dev/null)
ev_date=$(date -r "$start" +%Y-%m-%d 2>/dev/null)
today=$(date +%Y-%m-%d)
tomorrow=$(date -v+1d +%Y-%m-%d)
now=$(date +%s)

if [ "$ev_date" = "$today" ] || { [ "$start" -le "$now" ] && [ "$end" -gt "$now" ]; }; then
  echo "today $start $end" >"$STATE"
  sketchybar --set "$NAME" drawing=on label="$start_hm  $title"
elif [ "$ev_date" = "$tomorrow" ]; then
  echo "tomorrow" >"$STATE"
  sketchybar --set "$NAME" drawing=on label="$start_hm  $title"
else
  echo "chill" >"$STATE"
  sketchybar --set "$NAME" drawing=on label=""
fi
