#!/usr/bin/env bash
# Now playing — one pill per active source. Sources gathered independently:
#   sp = Spotify, mu = Apple Music   (AppleScript: work even when not the
#                                      system's current Now Playing app)
#   br = browser / other             (nowplaying-cli: macOS system Now Playing,
#                                      deduped against Spotify/Music by title)
# A playing pill shows art + icon + track (marquee if long); a paused pill
# collapses to just art + a pause glyph so it takes minimal space.

source "$HOME/.config/sketchybar/colors.sh"

W=20   # marquee visible window (keep in sync with media_marquee.sh)
NP="$(command -v nowplaying-cli || echo /opt/homebrew/bin/nowplaying-cli)"

pidfile() { echo "/tmp/sb_med_$1.pid"; }
ttlfile() { echo "/tmp/sb_med_$1.ttl"; }
marquee_alive() { p=$(cat "$(pidfile "$1")" 2>/dev/null); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
stop_marquee() {
  p=$(cat "$(pidfile "$1")" 2>/dev/null)
  [ -n "$p" ] && kill "$p" 2>/dev/null
  rm -f "$(pidfile "$1")" "$(ttlfile "$1")"
}
start_marquee() { # $1 item  $2 title
  marquee_alive "$1" && [ "$2" = "$(cat "$(ttlfile "$1")" 2>/dev/null)" ] && return
  stop_marquee "$1"
  "$HOME/.config/sketchybar/plugins/media_marquee.sh" "$1" "$2" &
  echo $! >"$(pidfile "$1")"
  echo "$2" >"$(ttlfile "$1")"
}

hide_slot() { # $1 key
  stop_marquee "med_$1"
  sketchybar --set "med_$1" drawing=off
  sketchybar --set "cov_$1" drawing=off background.image.drawing=off
  sketchybar --set "sep_med_$1" width=0
}

render_slot() { # $1 key  $2 state  $3 title  $4 artist  $5 cover_png
  k="$1"; state="$2"; title="$3"; artist="$4"; cover="$5"
  sketchybar --set "sep_med_$k" width="$GAP"
  if [ -n "$cover" ] && [ -f "$cover" ]; then
    sketchybar --set "cov_$k" drawing=on background.image="$cover" background.image.drawing=on background.image.scale=0.35
  else
    sketchybar --set "cov_$k" drawing=on background.image.drawing=off
  fi

  if [ "$state" = playing ]; then
    label="$title"; [ -n "$artist" ] && label="$artist – $title"
    sketchybar --set "med_$k" drawing=on icon="󰏤" icon.color="$GREEN"
    if [ "${#label}" -le "$W" ]; then
      stop_marquee "med_$k"
      sketchybar --set "med_$k" label.width=0 label="$label"
    else
      sketchybar --set "med_$k" label.width=170
      start_marquee "med_$k" "$label"
    fi
  else
    # paused -> art + play glyph only, no track name
    stop_marquee "med_$k"
    sketchybar --set "med_$k" drawing=on icon="󰐊" icon.color="$GREY" label="" label.width=0
  fi
}

# Refetch art only when a slot's track changes. Sets COVER (global) to a png
# path or "". $1 key, $2 id (track signature), $3 fetch command type, $4 arg.
fetch_cover() { # $1 key  $2 id  $3 kind(spotify_url|music_data|np_data)
  k="$1"; id="$2"; kind="$3"
  idf="/tmp/sb_med_$k.id"; src="/tmp/sb_med_$k.src"; png="/tmp/sb_med_$k.png"
  if [ "$id" != "$(cat "$idf" 2>/dev/null)" ]; then
    echo "$id" >"$idf"; rm -f "$src"
    case "$kind" in
      spotify_url)
        url=$(osascript -e 'tell application "Spotify" to artwork url of current track' 2>/dev/null)
        [ "${url:0:4}" = http ] && curl -fsL "$url" -o "$src" 2>/dev/null ;;
      music_data)
        osascript >/dev/null 2>&1 <<'OSA'
tell application "Music"
  if exists current track then
    set d to data of artwork 1 of current track
    set f to open for access (POSIX file "/tmp/sb_med_mu.src") with write permission
    set eof f to 0
    write d to f
    close access f
  end if
end tell
OSA
        ;;
      np_data)
        "$NP" get artworkData 2>/dev/null | base64 -D >"$src" 2>/dev/null ;;
    esac
    if [ -s "$src" ] && sips -s format png -z 60 60 "$src" -o "$png" >/dev/null 2>&1; then :; else rm -f "$png"; fi
  fi
  [ -f "$png" ] && COVER="$png" || COVER=""
}

###############################################################################
# Gather sources
###############################################################################
SP_STATE=""; SP_TITLE=""; SP_ARTIST=""; SP_COVER=""
MU_STATE=""; MU_TITLE=""; MU_ARTIST=""; MU_COVER=""
BR_STATE=""; BR_TITLE=""; BR_ARTIST=""; BR_COVER=""

read_player() { # $1 app -> echoes "state\ttitle\tartist"
  pgrep -xq "$1" || return 0
  s=$(osascript -e "tell application \"$1\" to player state as string" 2>/dev/null)
  [ "$s" = playing ] || [ "$s" = paused ] || return 0
  t=$(osascript -e "tell application \"$1\" to name of current track" 2>/dev/null)
  a=$(osascript -e "tell application \"$1\" to artist of current track" 2>/dev/null)
  printf '%s\t%s\t%s' "$s" "$t" "$a"
}

IFS=$'\t' read -r SP_STATE SP_TITLE SP_ARTIST < <(read_player Spotify)
IFS=$'\t' read -r MU_STATE MU_TITLE MU_ARTIST < <(read_player Music)

{ read -r NP_TITLE; read -r NP_ARTIST; read -r NP_RATE; } \
  < <("$NP" get title artist playbackRate 2>/dev/null)
[ "$NP_TITLE" = null ] && NP_TITLE=""
[ "$NP_ARTIST" = null ] && NP_ARTIST=""
if [ -n "$NP_TITLE" ] && [ "$NP_TITLE" != "$SP_TITLE" ] && [ "$NP_TITLE" != "$MU_TITLE" ]; then
  if [ -n "$NP_RATE" ] && [ "$NP_RATE" != 0 ] && [ "$NP_RATE" != null ]; then BR_STATE=playing; else BR_STATE=paused; fi
  BR_TITLE="$NP_TITLE"; BR_ARTIST="$NP_ARTIST"
fi

###############################################################################
# Render / hide each slot
###############################################################################
if [ -n "$SP_STATE" ]; then
  fetch_cover sp "$SP_ARTIST – $SP_TITLE" spotify_url; SP_COVER="$COVER"
  render_slot sp "$SP_STATE" "$SP_TITLE" "$SP_ARTIST" "$SP_COVER"
else hide_slot sp; fi

if [ -n "$MU_STATE" ]; then
  fetch_cover mu "$MU_ARTIST – $MU_TITLE" music_data; MU_COVER="$COVER"
  render_slot mu "$MU_STATE" "$MU_TITLE" "$MU_ARTIST" "$MU_COVER"
else hide_slot mu; fi

if [ -n "$BR_STATE" ]; then
  fetch_cover br "$BR_ARTIST – $BR_TITLE" np_data; BR_COVER="$COVER"
  render_slot br "$BR_STATE" "$BR_TITLE" "$BR_ARTIST" "$BR_COVER"
else hide_slot br; fi
