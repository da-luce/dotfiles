#!/usr/bin/env zsh

# zsh: default shell for Mac OSX

reload() {
  source ~/.zshrc
}

# Set tmux window + pane titles. Works locally and over SSH.
# Window name: last active pane wins (sensible with multiple panes).
# Pane title: per-pane, shown in the pane border via #{pane_title}.
_tmux_title() {
  [[ -z "$TMUX" ]] && return
  local branch repo title
  branch=$(git branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    title="$repo:$branch"
  else
    title=${PWD##*/}
  fi
  printf '\033]0;%s\007' "$title"   # OSC 0: sets #{pane_title} + window name (allow-rename on)
}
precmd_functions+=(_tmux_title)

# Source generic rc file
if [ -f "$HOME/.shell/rc" ]; then
    . "$HOME/.shell/rc"
fi

