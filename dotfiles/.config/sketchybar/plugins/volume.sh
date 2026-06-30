#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

case "$SENDER" in
  mouse.clicked)
    if [ "$(osascript -e 'output muted of (get volume settings)')" = "true" ]; then
      osascript -e 'set volume without output muted'
    else
      osascript -e 'set volume with output muted'
    fi
    ;;
  mouse.scrolled)
    CUR=$(osascript -e 'output volume of (get volume settings)')
    STEP=$(awk -v d="$SCROLL_DELTA" 'BEGIN { print (d > 0) ? 6 : -6 }')
    NEW=$((CUR + STEP))
    [ "$NEW" -gt 100 ] && NEW=100
    [ "$NEW" -lt 0 ] && NEW=0
    osascript -e "set volume output volume $NEW"
    ;;
esac

VOL=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

if [ "$MUTED" = "true" ] || [ "$VOL" -eq 0 ]; then
  ICON="󰖁"; COLOR=$GREY
elif [ "$VOL" -gt 60 ]; then
  ICON="󰕾"; COLOR=$CYAN
elif [ "$VOL" -gt 30 ]; then
  ICON="󰖀"; COLOR=$CYAN
else
  ICON="󰕿"; COLOR=$CYAN
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOL}%"
