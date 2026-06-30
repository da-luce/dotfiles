#!/usr/bin/env bash
# Play/pause whichever supported player is running.

for app in Spotify Music; do
  if pgrep -xq "$app"; then
    osascript -e "tell application \"$app\" to playpause" 2>/dev/null
    break
  fi
done

# Refresh the icon immediately instead of waiting for the next update tick
NAME="${NAME:-media}" "$HOME/.config/sketchybar/plugins/media.sh"
