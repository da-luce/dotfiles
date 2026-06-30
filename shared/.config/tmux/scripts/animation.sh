#!/usr/bin/env bash
# Background process: advances braille spinner frame and forces status bar refresh.
# Exits automatically when no agent panes are in the running state.

set -euo pipefail

cleanup() {
    tmux set-environment -gu TMUX_AGENT_ANIMATION_FRAME 2>/dev/null || true
    tmux set-environment -gu TMUX_AGENT_ANIMATION_PID 2>/dev/null || true
}
trap cleanup EXIT

tmux list-sessions >/dev/null 2>&1 || exit 0
tmux set-environment -g TMUX_AGENT_ANIMATION_PID "$$"

frame=0
while true; do
    tmux list-sessions >/dev/null 2>&1 || break
    tmux show-environment -g 2>/dev/null \
        | grep -q '^TMUX_AGENT_PANE_.*_STATE=running' || break
    tmux set-environment -g TMUX_AGENT_ANIMATION_FRAME "$frame" 2>/dev/null || break
    tmux refresh-client -S 2>/dev/null || true
    frame=$(( (frame + 1) % 8 ))
    sleep 0.3
done
