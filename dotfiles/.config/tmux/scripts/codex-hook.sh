#!/usr/bin/env bash
# Codex notify adapter — maps Codex lifecycle events to agent-state.sh calls.
# Drains stdin to avoid broken-pipe errors when Codex writes event data there.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STDIN_DATA=$(cat 2>/dev/null || true)
EVENT="${1:-${STDIN_DATA:-agent-turn-complete}}"

case "$EVENT" in
    start|session-start|turn-start|working)
        STATE="running" ;;
    permission*|approve*|needs-input|input-required|ask-user)
        STATE="needs-input" ;;
    *)
        STATE="done" ;;
esac

bash "$SCRIPT_DIR/agent-state.sh" --agent codex --state "$STATE"
