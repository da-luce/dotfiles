#!/usr/bin/env bash
# 1s driver — owns the calendar item's icon/colors based on the mode written by
# calendar.sh. (calendar.sh owns the label.)
#   chill    -> green palm tree
#   tomorrow -> calendar-with-arrow glyph
#   today    -> calendar glyph, plus:
#                 in-progress (now in [start,end)) -> blinking red dot
#                 upcoming <= 5 min                -> flash the whole pill red
#                 otherwise                        -> normal

source "$HOME/.config/sketchybar/colors.sh"

STATE=/tmp/sketchybar_next_meeting
TOGGLE=/tmp/sketchybar_meeting_flash

ICON_CAL="󰃭"
ICON_PALM="󱁕"       # palm-tree
ICON_DOT="●"

data=$(cat "$STATE" 2>/dev/null)
mode=${data%% *}

case "$mode" in
  chill)
    sketchybar --set calendar icon="$ICON_PALM" icon.color="$GREEN" \
               label.color="$WHITE" background.color="$ISLAND"
    ;;
  tomorrow)
    # calendar + chunky arrow, both in the bold icon font and purple; text stays white
    sketchybar --set calendar icon="$ICON_CAL ⇒" icon.color="$MAGENTA" \
               label.color="$WHITE" background.color="$ISLAND"
    ;;
  today)
    start=$(echo "$data" | awk '{print $2}')
    end=$(echo "$data" | awk '{print $3}')
    now=$(date +%s)
    [ "$(cat "$TOGGLE" 2>/dev/null)" = "1" ] && nt=0 || nt=1
    echo "$nt" >"$TOGGLE"

    if [ "$now" -ge "$start" ] && [ "$now" -lt "$end" ]; then
      # in-progress: blinking red dot
      [ "$nt" = "1" ] && dot="$RED" || dot=0x00000000
      sketchybar --set calendar icon="$ICON_DOT" icon.color="$dot" \
                 label.color="$WHITE" background.color="$ISLAND"
    elif [ $(( (start - now) / 60 )) -ge 0 ] && [ $(( (start - now) / 60 )) -le 5 ]; then
      # imminent: flash pill
      if [ "$nt" = "1" ]; then
        sketchybar --set calendar icon="$ICON_CAL" background.color="$RED" \
                   icon.color="$WHITE" label.color="$WHITE"
      else
        sketchybar --set calendar icon="$ICON_CAL" background.color="$ISLAND" \
                   icon.color="$RED" label.color="$RED"
      fi
    else
      sketchybar --set calendar icon="$ICON_CAL" icon.color="$MAGENTA" \
                 label.color="$WHITE" background.color="$ISLAND"
    fi
    ;;
  *)
    sketchybar --set calendar icon="$ICON_CAL" icon.color="$MAGENTA" \
               label.color="$WHITE" background.color="$ISLAND"
    ;;
esac
