#!/usr/bin/env bash
# Per-pane agent indicator for status-right.
# Spinner driven by TMUX_AGENT_ANIMATION_FRAME (updated by animation.sh every 300ms).
# Running: animated circle  Done/needs-input: solid dot in window colour.

window_id=$(tmux display-message -p '#{window_id}')

# Braille spinner frames: ⣾⣽⣻⢿⡿⣟⣯⣷
S0=$(printf '\xe2\xa3\xbe')
S1=$(printf '\xe2\xa3\xbd')
S2=$(printf '\xe2\xa3\xbb')
S3=$(printf '\xe2\xa2\xbf')
S4=$(printf '\xe2\xa1\xbf')
S5=$(printf '\xe2\xa3\x9f')
S6=$(printf '\xe2\xa3\xaf')
S7=$(printf '\xe2\xa3\xb7')
frames=("$S0" "$S1" "$S2" "$S3" "$S4" "$S5" "$S6" "$S7")

frame=$(tmux show-environment -g TMUX_AGENT_ANIMATION_FRAME 2>/dev/null | sed 's/^[^=]*=//')
[ -z "$frame" ] && frame=0
spin="${frames[$((frame % 8))]}"

out=""
while IFS= read -r pane_id; do
    state=$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_STATE" 2>/dev/null \
        | sed 's/^[^=]*=//')
    [ -z "$state" ] || [ "$state" = "off" ] && continue
    case "$state" in
        running)     out="${out}#[fg=colour4]${spin}#[default] " ;;
        done)        out="${out}#[fg=colour2]●#[default] " ;;
        needs-input) out="${out}#[fg=colour3]●#[default] " ;;
    esac
done < <(tmux list-panes -t "$window_id" -F '#{pane_id}')

printf '%s' "$out"
