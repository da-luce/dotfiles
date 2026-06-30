#!/usr/bin/env bash
# Installs the agent-indicator + assistant-resurrect hooks for Claude Code,
# Codex, and OpenCode on the current machine. Paths are baked from $HOME at
# install time, so the same script works on macOS and the Arca dev box.
#
# Safe to re-run: Claude hooks are merged (deduped) into any existing
# settings.json, the Codex notify line is only added if absent, and the
# OpenCode plugin is overwritten in place. Existing/managed config is kept.
#
# Prereqs: tmux config stowed at ~/.config/tmux (run `stow shared` first) and
# `jq` available. Resurrect hooks need tmux-assistant-resurrect installed via
# TPM (prefix + I) before they do anything.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$HOME/.config/tmux/scripts"
RESURRECT="$HOME/.config/tmux/plugins/tmux-assistant-resurrect/hooks"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }

###############################################################################
# Claude Code — merge hooks into ~/.claude/settings.json
###############################################################################
CLAUDE="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
[ -f "$CLAUDE" ] || echo '{}' >"$CLAUDE"

frag=$(cat <<JSON
{
  "SessionStart": [{"matcher":"","hooks":[{"type":"command","command":"bash '$RESURRECT/claude-session-track.sh'"}]}],
  "SessionEnd":   [{"matcher":"","hooks":[{"type":"command","command":"bash '$RESURRECT/claude-session-cleanup.sh'"}]}],
  "UserPromptSubmit": [
    {"matcher":"","hooks":[{"type":"command","command":"bash '$SCRIPTS/agent-state.sh' --agent claude --state off"}]},
    {"matcher":"","hooks":[{"type":"command","command":"bash '$SCRIPTS/agent-state.sh' --agent claude --state running"}]}
  ],
  "PermissionRequest": [{"matcher":"","hooks":[{"type":"command","command":"bash '$SCRIPTS/agent-state.sh' --agent claude --state needs-input"}]}],
  "Stop":              [{"matcher":"","hooks":[{"type":"command","command":"bash '$SCRIPTS/agent-state.sh' --agent claude --state done"}]}]
}
JSON
)

tmp=$(mktemp)
jq --argjson frag "$frag" '
  .hooks = ((.hooks // {}) as $h
    | reduce ($frag | to_entries[]) as $e ($h;
        .[$e.key] = (((.[$e.key] // []) + $e.value) | unique_by(tojson))))
' "$CLAUDE" >"$tmp" && mv "$tmp" "$CLAUDE"
echo "✓ Claude hooks merged into $CLAUDE"

###############################################################################
# Codex — ensure notify line in ~/.codex/config.toml (never overwrite secrets)
###############################################################################
CODEX="$HOME/.codex/config.toml"
mkdir -p "$HOME/.codex"
touch "$CODEX"

if grep -q 'codex-hook.sh' "$CODEX"; then
  echo "✓ Codex notify already configured"
elif grep -q '^notify' "$CODEX"; then
  echo "! Codex has a different 'notify' set; leaving it. Add manually if wanted:" >&2
  echo "    notify = [\"bash\", \"$SCRIPTS/codex-hook.sh\"]" >&2
else
  # Top-level key must precede any [table]; prepend to stay valid TOML.
  tmp=$(mktemp)
  { printf 'notify = ["bash", "%s/codex-hook.sh"]\n' "$SCRIPTS"; cat "$CODEX"; } >"$tmp"
  mv "$tmp" "$CODEX"
  echo "✓ Codex notify added to $CODEX"
fi

###############################################################################
# OpenCode — drop the indicator plugin if OpenCode is present
###############################################################################
if [ -d "$HOME/.config/opencode" ]; then
  mkdir -p "$HOME/.config/opencode/plugins"
  cp "$HERE/agent-hooks/opencode-tmux-agent-indicator.js" \
     "$HOME/.config/opencode/plugins/opencode-tmux-agent-indicator.js"
  echo "✓ OpenCode plugin installed"
else
  echo "- OpenCode not found; skipping plugin"
fi

echo "Done. Agent indicators active after the next agent session in tmux."
