#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

BATT="$(pmset -g batt)"
PERCENTAGE="$(echo "$BATT" | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(echo "$BATT" | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
  9[0-9]|100) ICON="󰁹"; COLOR=$GREEN ;;
  [6-8][0-9]) ICON="󰂁"; COLOR=$GREEN ;;
  [3-5][0-9]) ICON="󰁾"; COLOR=$YELLOW ;;
  [1-2][0-9]) ICON="󰁻"; COLOR=$YELLOW ;;
  *)          ICON="󰂃"; COLOR=$RED ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="󰂄"
  COLOR=$GREEN
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"

# Popup detail: time remaining / charging state
REMAIN="$(echo "$BATT" | grep -Eo '[0-9]+:[0-9]+ remaining' | head -1)"
if [ -n "$CHARGING" ]; then
  DETAIL="Charging"
elif [ -n "$REMAIN" ]; then
  DETAIL="${REMAIN% remaining} left"
else
  DETAIL="Calculating…"
fi
sketchybar --set battery.detail label="$DETAIL"
