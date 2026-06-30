#!/usr/bin/env bash
# Toggle play/pause for a specific media pill. $1 = source key:
#   sp -> Spotify, mu -> Apple Music (AppleScript), br/* -> system Now Playing.

NP="$(command -v nowplaying-cli || echo /opt/homebrew/bin/nowplaying-cli)"

case "$1" in
  sp) pgrep -xq Spotify && osascript -e 'tell application "Spotify" to playpause' 2>/dev/null ;;
  mu) pgrep -xq Music   && osascript -e 'tell application "Music" to playpause' 2>/dev/null ;;
  *)  "$NP" togglePlayPause 2>/dev/null ;;
esac

# Refresh immediately instead of waiting for the next update tick
"$HOME/.config/sketchybar/plugins/media.sh"
