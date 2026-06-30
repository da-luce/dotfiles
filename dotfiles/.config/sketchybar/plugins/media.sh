#!/usr/bin/env bash
# Now playing via macOS MediaRemote (nowplaying-cli) — works for any app that
# publishes Now Playing info: Spotify, Music, and browsers (YouTube, etc.).
# Album art is decoded from the framework's artwork data and refetched only
# when the track changes. Long titles use a DIY ping-pong marquee (native
# label scrolling is broken in this build).

source "$HOME/.config/sketchybar/colors.sh"

SRC=/tmp/sb_cover_src
COVER=/tmp/sketchybar_cover.png
IDFILE=/tmp/sketchybar_media_track
MPID=/tmp/sketchybar_marquee.pid
MTTL=/tmp/sketchybar_marquee.title
W=20   # keep in sync with media_marquee.sh
NP="$(command -v nowplaying-cli || echo /opt/homebrew/bin/nowplaying-cli)"

marquee_alive() { [ -f "$MPID" ] && kill -0 "$(cat "$MPID" 2>/dev/null)" 2>/dev/null; }
stop_marquee() { marquee_alive && kill "$(cat "$MPID")" 2>/dev/null; rm -f "$MPID" "$MTTL"; }

# One framework query for the lot (bash 3.2: no mapfile). Each field is a line.
{ read -r TITLE; read -r ARTIST; read -r RATE; } \
  < <("$NP" get title artist playbackRate 2>/dev/null)
[ "$TITLE" = "null" ] && TITLE=""

# Nothing registered -> hide everything, collapse its gap, stop scrolling
if [ -z "$TITLE" ]; then
  stop_marquee
  sketchybar --set media drawing=off
  sketchybar --set media_cover drawing=off background.image.drawing=off
  sketchybar --set sep_media width=0
  : >"$IDFILE"
  exit 0
fi

# Media is showing -> restore its leading gap
sketchybar --set sep_media width="$GAP"

# playbackRate: >0 playing, 0/empty paused
if [ -n "$RATE" ] && [ "$RATE" != "0" ] && [ "$RATE" != "null" ]; then
  ICON="󰏤"; COLOR=$GREEN
else
  ICON="󰐊"; COLOR=$GREY
fi

LABEL="$TITLE"
[ -n "$ARTIST" ] && [ "$ARTIST" != "null" ] && LABEL="$ARTIST – $TITLE"

sketchybar --set media drawing=on icon="$ICON" icon.color="$COLOR"

# --- Scrolling label ---
if [ "${#LABEL}" -le "$W" ]; then
  stop_marquee
  sketchybar --set media label.width=0 label="$LABEL"
else
  sketchybar --set media label.width=170
  if ! marquee_alive || [ "$LABEL" != "$(cat "$MTTL" 2>/dev/null)" ]; then
    stop_marquee
    "$HOME/.config/sketchybar/plugins/media_marquee.sh" "$LABEL" &
    echo $! >"$MPID"
    echo "$LABEL" >"$MTTL"
  fi
fi

# --- Album art (refetch only when the track changes) ---
TID="$LABEL"
if [ "$TID" != "$(cat "$IDFILE" 2>/dev/null)" ]; then
  echo "$TID" >"$IDFILE"
  rm -f "$SRC"
  "$NP" get artworkData 2>/dev/null | base64 -D >"$SRC" 2>/dev/null
  if [ -s "$SRC" ] && sips -s format png -z 60 60 "$SRC" -o "$COVER" >/dev/null 2>&1; then
    :
  else
    rm -f "$COVER"
  fi
fi

if [ -f "$COVER" ]; then
  sketchybar --set media_cover drawing=on \
             background.image="$COVER" background.image.drawing=on background.image.scale=0.35
else
  sketchybar --set media_cover drawing=off background.image.drawing=off
fi
