#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Bash specifc stuff

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth:erasedups

# append to history file, don't overwrite it
shopt -s histappend

# setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary, update the values
# of LINES and COLUMNS.
shopt -s checkwinsize

# set a fancy prompt (non-color, unless we know we "want" color)
# Not sure what this does
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned off
# by default to not distract the user: the focus in a terminal window should be
# on the output of commands, not on the prompt
force_color_prompt=yes

reload() {
  echo "🔄 Reloading ~/.bashrc"
  source ~/.bashrc
}

# Source generic rc file
if [ -f "$HOME/.shell/rc" ]; then
    . "$HOME/.shell/rc"
fi
. "$HOME/.cargo/env"
