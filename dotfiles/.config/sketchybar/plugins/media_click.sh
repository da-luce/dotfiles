#!/usr/bin/env bash
# Toggle play/pause for whatever owns macOS Now Playing (Spotify, Music,
# browser media like YouTube, ...) via MediaRemote.

NP="$(command -v nowplaying-cli || echo /opt/homebrew/bin/nowplaying-cli)"
"$NP" togglePlayPause 2>/dev/null

# Refresh the icon immediately instead of waiting for the next update tick
NAME="${NAME:-media}" "$HOME/.config/sketchybar/plugins/media.sh"
