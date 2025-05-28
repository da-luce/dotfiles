#!/bin/sh

# General .rc file for interactive shells

# If not running interactively, don't do anything
case $- in
    *i*);;      # interactive
    *) return;; # script
esac

# Source other important shell things (broken into own file as it has OS specific stuff)
safe_source "$HOME/.shell/util.sh"
safe_source "$HOME/.shell/alias.sh"
safe_source "$HOME/.shell/source.sh"
safe_source "$HOME/.shell/path.sh"

# For Xquartz
if command -v xhost &> /dev/null
then
  xhost +localhost
fi

# opam configuration
test -r /Users/sixsa/.opam/opam-init/init.sh && . /Users/sixsa/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true

# fancy prompt with starship
eval "$(starship init "$SHELL")"

# Something homebrew related
eval "$(/opt/homebrew/bin/brew shellenv)"

# Run mwinit command to establish secure session
retry_command "mwinit -o -s"