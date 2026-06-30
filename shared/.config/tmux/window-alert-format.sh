#!/usr/bin/env bash
# Sets glyph-containing format strings after TPM loads.
# Python3 generates chars from explicit codepoints — no tool/encoding ambiguity.

bg=$(tmux show-options -gqv "@status-bg")
[ -z "$bg" ] && bg="#222222"

py() { python3 -c "import sys; sys.stdout.write(chr($1))"; }

L=$(py 0xe0b6)   # U+E0B6  left rounded pill cap  (
R=$(py 0xe0b4)   # U+E0B4  right rounded pill cap )

icon_prefix=$(py 0xf0633)   # nf-md-keyboard
icon_copy=$(py 0xf0c5)      # nf-fa-copy
icon_tree=$(py 0xf115)      # nf-fa-folder_open

###############################################################################
# status-left — session name pill
# Priority: tree-mode (cyan) > copy-mode (yellow) > prefix (magenta) > normal
# Normal uses invisible pill chars so width stays stable across state changes.
###############################################################################

normal="#[bg=${bg} fg=${bg}]${L}#[fg=colour8] #S  #[fg=${bg}]${R}"
prefix="#[bg=${bg} fg=colour5]${L}#[bg=colour5 fg=${bg} bold] #S ${icon_prefix} #[bg=${bg} fg=colour5]${R}"
copy="#[bg=${bg} fg=colour3]${L}#[bg=colour3 fg=${bg} bold] #S ${icon_copy} #[bg=${bg} fg=colour3]${R}"
tree="#[bg=${bg} fg=colour6]${L}#[bg=colour6 fg=${bg} bold] #S ${icon_tree} #[bg=${bg} fg=colour6]${R}"

left="#{?pane_in_mode,#{?#{==:#{pane_mode},tree-mode},${tree},${copy}},#{?client_prefix,${prefix},${normal}}}"
tmux set-option -g status-left "$left"
tmux set-option -g status-left-length 40

###############################################################################
# window-status-format — pill script handles agent colors + bell override
###############################################################################

pill="$HOME/.config/tmux/window-pill.sh"
bell="#[bg=${bg} fg=colour5]${L}#[bg=colour5 fg=${bg} bold] #W #[bg=${bg} fg=colour5]${R}"

tab="#{?window_bell_flag,${bell},#($pill '#{window_id}' '#{window_active}' '#{window_zoomed_flag}')}"

tmux set-option -g window-status-bell-style     "none"
tmux set-option -g window-status-activity-style "none"
tmux set-option -g window-status-format         "$tab"
tmux set-option -g window-status-current-format "$tab"

