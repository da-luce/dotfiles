#!/usr/bin/env bash
# Re-assert manually-set window names after a resurrect/continuum restore.
#
# Symptom this fixes: after a reboot, manually-named windows come back named
# "cd" (or another command). Root cause: automatic-rename-format is
# #{pane_current_command}, and on restore automatic-rename doesn't reliably stay
# off — so the `cd <cwd>; <resume>` that tmux-assistant-resurrect replays into
# panes gets caught by automatic-rename and renames the window.
#
# resurrect's own restore_window_properties sets automatic-rename per window, but
# it races with the replayed pane commands. Rather than depend on that, this
# reads the save file (the source of truth) and, for every window saved with
# automatic-rename=off, re-applies the saved name and locks BOTH rename levers
# (automatic-rename off = no command-driven rename; allow-rename off = no
# escape-sequence rename). Runs from the post-restore-all hook, after the
# assistant replay has fired.

set -u

resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
[ -d "$resurrect_dir" ] || resurrect_dir="$HOME/.tmux/resurrect"
last="$resurrect_dir/last"
[ -e "$last" ] || exit 0

# Give the assistant replay a moment to send its `cd` lines first, so our
# re-assert lands last and wins.
sleep 2

# Window line format (tab-separated), see tmux-resurrect save.sh:
#   window <session> <index> <name> <active> <flags> <layout> <automatic_rename>
# Fields carry a leading ':' quote char that must be stripped. automatic_rename
# is literally "off" when locked, or ":" (empty) when unset/inheriting global.
grep '^window' "$last" | while IFS=$'\t' read -r _ session index name _ _ _ auto; do
    [ "${auto#:}" = "off" ] || continue          # only windows that were locked
    name="${name#:}"                             # strip the quote char
    target="${session}:${index}"
    tmux set-window-option -t "$target" automatic-rename off 2>/dev/null
    tmux set-window-option -t "$target" allow-rename off 2>/dev/null
    tmux rename-window -t "$target" "$name" 2>/dev/null
done
