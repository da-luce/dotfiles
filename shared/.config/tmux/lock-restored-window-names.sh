#!/usr/bin/env bash
# resurrect restores `automatic-rename` but not `allow-rename`. On a boot
# restore, allow-rename reverts to the global `on`, so the first shell prompt's
# OSC 0 title escape (see _tmux_title in .zshrc) clobbers the restored name.
# Lock allow-rename off for every window restored with automatic-rename off —
# the same windows the manual `bind ,` locks.
# Read the per-window automatic-rename OPTION value (what resurrect restores),
# not the #{automatic_rename} format — that reports a runtime flag that is "off"
# even for auto-named windows, which would wrongly lock every window.
tmux list-windows -a -F '#{window_id}' | \
    while read -r wid; do
        auto="$(tmux show-window-options -vt "$wid" automatic-rename 2>/dev/null)"
        [ "$auto" = "off" ] && tmux set-window-option -t "$wid" allow-rename off
    done
