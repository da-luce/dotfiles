#!/usr/bin/env bash

# ~/.bashrc is sourced by non-login interactive shells, such as those started by terminal
# windows (most configs also source .bashrc in interactive login shells though). This is 
# where you set things specific to your interactive shell that aren't otherwise inherited
# from the parent process. For example, PS1 is set here because only interactive shell
#  care about its value, and any interactive shell will source .bashrc anyway, so there
# is no need to define and export PS1 from .profile.

# Bash specifics go in here

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# If not bash, don't run this.
# TODO: fix this line...
if ! [[ "$BASH" ]]; then
    return
fi

# Bash specific stuff

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

# Amazon Brazil completion?
safe_source /Users/daluce/.brazil_completion/bash_completion 

# Source generic rc file
safe_source $HOME/.shell/rc.sh
