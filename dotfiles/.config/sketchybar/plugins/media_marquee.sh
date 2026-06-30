#!/usr/bin/env bash
# Ping-pong marquee for a media pill's label (native label scrolling is broken
# in this SketchyBar build). $1 = target item name, $2 = full title. Slides a
# fixed-width window back and forth, dwelling at each end. Exits if --set fails
# (sketchybar gone) or if the title no longer fits.

item="$1"
title="$2"
W=20                       # visible window in characters (JetBrainsMono is monospace)
L=${#title}

if [ "$L" -le "$W" ]; then
  sketchybar --set "$item" label="$title" 2>/dev/null
  exit 0
fi

pos=0
dir=1
max=$((L - W))

while true; do
  sketchybar --set "$item" label="${title:pos:W}" 2>/dev/null || exit 0
  next=$((pos + dir))
  if [ "$next" -gt "$max" ] || [ "$next" -lt 0 ]; then
    dir=$(( -dir ))        # reached an end -> reverse + dwell
    sleep 1.2
  else
    pos=$next
    sleep 0.28
  fi
done
