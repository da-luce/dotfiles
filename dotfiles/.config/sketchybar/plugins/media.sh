#!/usr/bin/env bash
# Now playing via AppleScript (Spotify / Music) with album art + a DIY ping-pong
# marquee for long titles (native label scrolling is broken in this build).
# Art is refetched only when the track changes.

source "$HOME/.config/sketchybar/colors.sh"

SRC=/tmp/sb_cover_src
COVER=/tmp/sketchybar_cover.png
IDFILE=/tmp/sketchybar_media_track
MPID=/tmp/sketchybar_marquee.pid
MTTL=/tmp/sketchybar_marquee.title
W=20   # keep in sync with media_marquee.sh

marquee_alive() { [ -f "$MPID" ] && kill -0 "$(cat "$MPID" 2>/dev/null)" 2>/dev/null; }
stop_marquee() { marquee_alive && kill "$(cat "$MPID")" 2>/dev/null; rm -f "$MPID" "$MTTL"; }

player=""
state=""
for app in Spotify Music; do
  if pgrep -xq "$app"; then
    s=$(osascript -e "tell application \"$app\" to player state as string" 2>/dev/null)
    if [ "$s" = "playing" ] || [ "$s" = "paused" ]; then
      player="$app"; state="$s"; break
    fi
  fi
done

# Nothing playing/paused -> hide everything, collapse its gap, stop scrolling
if [ -z "$player" ]; then
  stop_marquee
  sketchybar --set media drawing=off
  sketchybar --set media_cover drawing=off background.image.drawing=off
  sketchybar --set sep_media width=0
  : >"$IDFILE"
  exit 0
fi

# Media is showing -> restore its leading gap
sketchybar --set sep_media width="$GAP"

if [ "$state" = "playing" ]; then ICON="󰏤"; COLOR=$GREEN; else ICON="󰐊"; COLOR=$GREY; fi

TRACK=$(osascript -e "tell application \"$player\" to name of current track" 2>/dev/null)
ARTIST=$(osascript -e "tell application \"$player\" to artist of current track" 2>/dev/null)
LABEL="$TRACK"
[ -n "$ARTIST" ] && LABEL="$ARTIST – $TRACK"

sketchybar --set media drawing=on icon="$ICON" icon.color="$COLOR"

# --- Scrolling label ---
if [ "${#LABEL}" -le "$W" ]; then
  # short: compact, auto-width, no scroll
  stop_marquee
  sketchybar --set media label.width=0 label="$LABEL"
else
  # long: fixed-width box (no jitter) + ping-pong marquee
  sketchybar --set media label.width=170
  if ! marquee_alive || [ "$LABEL" != "$(cat "$MTTL" 2>/dev/null)" ]; then
    stop_marquee
    "$HOME/.config/sketchybar/plugins/media_marquee.sh" "$LABEL" &
    echo $! >"$MPID"
    echo "$LABEL" >"$MTTL"
  fi
fi

# --- Album art (refetch only when the track changes) ---
TID=$(osascript -e "tell application \"$player\" to id of current track" 2>/dev/null)
[ -z "$TID" ] && TID="$LABEL"

if [ "$TID" != "$(cat "$IDFILE" 2>/dev/null)" ]; then
  echo "$TID" >"$IDFILE"
  rm -f "$SRC"
  if [ "$player" = "Spotify" ]; then
    url=$(osascript -e 'tell application "Spotify" to artwork url of current track' 2>/dev/null)
    [[ "$url" == http* ]] && curl -fsL "$url" -o "$SRC" 2>/dev/null
  else
    osascript >/dev/null 2>&1 <<'OSA'
tell application "Music"
  if exists current track then
    set d to data of artwork 1 of current track
    set f to open for access (POSIX file "/tmp/sb_cover_src") with write permission
    set eof f to 0
    write d to f
    close access f
  end if
end tell
OSA
  fi
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
