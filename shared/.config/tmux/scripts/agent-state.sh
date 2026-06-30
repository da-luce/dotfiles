#!/usr/bin/env bash
# Sets agent state in tmux global environment for the current pane.
# Called by Claude Code and Codex hooks via --agent <name> --state <state>.

set -euo pipefail

[ -z "${TMUX:-}" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

agent="" state=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --agent) agent="$2"; shift 2 ;;
        --state) state="$2"; shift 2 ;;
        *) shift ;;
    esac
done

pane_id="${TMUX_PANE:-}"
[ -z "$pane_id" ] && exit 0

STATE_KEY="TMUX_AGENT_PANE_${pane_id}_STATE"
AGENT_KEY="TMUX_AGENT_PANE_${pane_id}_AGENT"

has_running_panes() {
    tmux show-environment -g 2>/dev/null | grep -q '^TMUX_AGENT_PANE_.*_STATE=running'
}

stop_animation() {
    has_running_panes && return
    local pid
    pid=$(tmux show-environment -g TMUX_AGENT_ANIMATION_PID 2>/dev/null \
        | sed 's/^[^=]*=//' || true)
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
    tmux set-environment -gu TMUX_AGENT_ANIMATION_PID 2>/dev/null || true
    tmux set-environment -gu TMUX_AGENT_ANIMATION_FRAME 2>/dev/null || true
}

start_animation() {
    local pid
    pid=$(tmux show-environment -g TMUX_AGENT_ANIMATION_PID 2>/dev/null \
        | sed 's/^[^=]*=//' || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        return
    fi
    bash "$SCRIPT_DIR/animation.sh" &
    disown
}

case "$state" in
    running)
        tmux set-environment -g "$STATE_KEY" "running"
        [ -n "$agent" ] && tmux set-environment -g "$AGENT_KEY" "$agent"
        start_animation
        ;;
    needs-input)
        tmux set-environment -g "$STATE_KEY" "needs-input"
        [ -n "$agent" ] && tmux set-environment -g "$AGENT_KEY" "$agent"
        stop_animation
        ;;
    done)
        tmux set-environment -g "$STATE_KEY" "done"
        [ -n "$agent" ] && tmux set-environment -g "$AGENT_KEY" "$agent"
        stop_animation
        ;;
    off)
        tmux set-environment -gu "$STATE_KEY" 2>/dev/null || true
        tmux set-environment -gu "$AGENT_KEY" 2>/dev/null || true
        stop_animation
        ;;
esac

tmux refresh-client -S 2>/dev/null || true
