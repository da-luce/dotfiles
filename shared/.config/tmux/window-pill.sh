#!/usr/bin/env bash
# Outputs a tmux format string for one window tab pill.
# Reads TMUX_AGENT_PANE_*_STATE env vars written by scripts/agent-state.sh.

WINDOW_ID="${1:-}"
ACTIVE="${2:-0}"
ZOOMED="${3:-0}"

BG="#222222"
L=$(printf '\xee\x82\xb6')   # U+E0B6  (
R=$(printf '\xee\x82\xb4')   # U+E0B4  )

WINDOW_NAME=$(tmux display-message -p -t "$WINDOW_ID" '#{window_name}' 2>/dev/null)
ZOOM=$(printf '\xef\x81\xa5')  # U+F065 nf-fa-expand
[ "$ZOOMED" = "1" ] && WINDOW_NAME="${WINDOW_NAME} ${ZOOM}"

# Find the most urgent agent state across all panes in this window.
# Priority: needs-input > running > done
# Running takes priority over done so one finished agent doesn't mask one still working.
state=""
while IFS= read -r pane_id; do
    s=$(tmux show-environment -g "TMUX_AGENT_PANE_${pane_id}_STATE" 2>/dev/null \
        | sed 's/^[^=]*=//')
    case "$s" in
        needs-input) state="needs-input"; break ;;
        running)     state="running" ;;
        done)        [ "$state" != "running" ] && state="done" ;;
    esac
done < <(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null)

pill() {
    local fill="$1" text="$2"
    printf '#[bg=%s fg=%s]%s#[bg=%s fg=%s] %s #[bg=%s fg=%s]%s' \
        "$BG" "$fill" "$L" "$fill" "$text" "$WINDOW_NAME" "$BG" "$fill" "$R"
}

SEEN_KEY="TMUX_AGENT_WINDOW_${WINDOW_ID}_DONE_SEEN"

if [ "$ACTIVE" = "1" ]; then
    if [ "$state" = "done" ]; then
        tmux set-environment -g "$SEEN_KEY" "1" 2>/dev/null
        pill colour2 colour0
    else
        tmux set-environment -gu "$SEEN_KEY" 2>/dev/null
        pill colour4 colour0
    fi
else
    seen=$(tmux show-environment -g "$SEEN_KEY" 2>/dev/null | sed 's/^[^=]*=//')
    if [ "$state" = "done" ] && [ "$seen" = "1" ]; then
        tmux set-environment -gu "$SEEN_KEY" 2>/dev/null
        while IFS= read -r pid; do
            s=$(tmux show-environment -g "TMUX_AGENT_PANE_${pid}_STATE" 2>/dev/null \
                | sed 's/^[^=]*=//')
            [ "$s" = "done" ] || continue
            tmux set-environment -gu "TMUX_AGENT_PANE_${pid}_STATE" 2>/dev/null
            tmux set-environment -gu "TMUX_AGENT_PANE_${pid}_AGENT" 2>/dev/null
        done < <(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id}' 2>/dev/null)
        printf '#[fg=colour8] %s ' "$WINDOW_NAME"
    else
        case "$state" in
            needs-input) pill colour3 colour0 ;;
            done)        pill colour2 colour0 ;;
            running)     pill colour4 colour0 ;;
            *)           printf '#[fg=colour8] %s ' "$WINDOW_NAME" ;;
        esac
    fi
fi
