# Agent Indicator Spec

## Overview

Window tabs in tmux should communicate agent activity at a glance. The active window
is always visually distinct. Other windows are dim by default, lighting up only when
an agent in them needs attention.

---

## Window Tab States

### No agent / idle
- **Appearance:** dim text, no pill shape
- **Color:** terminal default (colour8)
- **Clears when:** n/a — default state

### Active window (any agent state)
- **Appearance:** pill shape
- **Color:** terminal blue (colour4)
- **Notes:** agent state colors are suppressed for the active window — the user
  can see the terminal directly

### Agent working (running / reasoning / typing)
- **Appearance:** pill shape
- **Color:** terminal blue (colour4) — same as active, distinct from idle
- **Clears when:** agent finishes (transitions to done or needs-input)

### Agent done (chat finished)
- **Appearance:** pill shape
- **Color:** terminal green (colour2)
- **Clears when:** user marks as seen (see Seen Semantics below)

### Agent needs input (permission request)
- **Appearance:** pill shape
- **Color:** terminal yellow (colour3)
- **Clears when:** user gives input (next prompt submitted) — NOT on window/pane switch

---

## Seen Semantics

"Seen" means the user has acknowledged the agent's state. Rules differ based on
whether the user was already in the window when the state changed.

### User is in a different window/pane when state changes
- The tab lights up immediately (done → green, working → blue pill)
- Marked as seen when the user **switches to that window or pane**
- On seen: tab returns to active-window color (blue pill) or idle if no agent

### User is already in the window/pane when state changes
- **Done:** tab shows green; marked as seen when the user **responds or leaves the window**
- **Working:** tab shows blue pill (same as active); no explicit seen action needed
- **Needs input:** NOT marked as seen on leave — requires an actual response

### Needs-input is special
- Never cleared by switching windows or panes
- Only cleared when the user submits a response (UserPromptSubmit / new prompt)
- This ensures permission requests are never silently dismissed

---

## Corner Indicator (status-right)

One indicator per agent pane in the current window.

| State       | Symbol             | Color           |
|-------------|--------------------|-----------------|
| Working     | braille spinner    | terminal blue (colour4) |
| Done        | ● solid dot        | terminal green (colour2) |
| Needs input | ● solid dot        | terminal yellow (colour3) |

The spinner is animated via a background process updating a frame counter every ~300ms.

---

## Session Name Pill

The session name pill (`status-left`) is always rendered on top of the window tab
list — it should visually feel like it floats above the tabs rather than sitting
alongside them. In practice this means:

- `status-left` is given sufficient length so it is never truncated or pushed aside
- The window list (`status-justify absolute-centre`) may be obscured by the session
  pill when windows are numerous, and that is intentional — the session pill wins
- The pill shape and background color are consistent regardless of how many windows
  are open

---

## Design Constraints

- **Terminal colors only** — no hardcoded hex values in state colors; use colour0–colour15
- **No pane background coloring**
- **No pane border coloring**
- **No tmux display-message notifications** (status bar takeover)
- **Pill shape** uses Powerline glyphs U+E0B6 / U+E0B4 for rounded caps
- Background color of the pill caps matches the terminal background (`#222222`) for
  seamless rendering

---

## Implementation Components

| File | Role |
|------|------|
| `window-pill.sh` | Renders one window tab; reads agent state env vars |
| `window-alert-format.sh` | Sets tmux format strings after TPM loads; runs post-plugin |
| `multi-indicator.sh` | Renders per-pane dots/spinner for status-right |
| `scripts/agent-state.sh` | Sets `TMUX_AGENT_PANE_${pane_id}_STATE` in tmux global env |
| `scripts/animation.sh` | Background process; updates `TMUX_AGENT_ANIMATION_FRAME` + refresh |
| `~/.claude/settings.json` | Claude Code hooks → agent-state.sh |
| `~/.codex/config.toml` | Codex notify hook → agent-state.sh |

### State env vars (tmux global environment)

```
TMUX_AGENT_PANE_${pane_id}_STATE   = running | needs-input | done | (unset)
TMUX_AGENT_PANE_${pane_id}_AGENT   = claude | codex
TMUX_AGENT_ANIMATION_FRAME         = 0–7 (updated by animation.sh)
TMUX_AGENT_ANIMATION_PID           = PID of animation.sh background process
TMUX_AGENT_WINDOW_${window_id}_DONE_SEEN = 1 | (unset)
```

---

## Hook Events

### Claude Code (`~/.claude/settings.json`)

| Event | Action |
|-------|--------|
| `UserPromptSubmit` | `--state running` |
| `PermissionRequest` | `--state needs-input` |
| `Stop` | `--state done` |

### Codex (`~/.codex/config.toml` → notify)

| Event | Action |
|-------|--------|
| `turn-start` / `working` | `--state running` |
| `permission*` / `needs-input` | `--state needs-input` |
| `agent-turn-complete` / `done` / `error` | `--state done` |
