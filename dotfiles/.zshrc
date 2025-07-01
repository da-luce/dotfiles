#!/usr/bin/env zsh

# zsh: default shell for Mac OSX

reload() {
  source ~/.zshrc
}

# Source generic rc file
if [ -f "$HOME/.shell/rc" ]; then
    . "$HOME/.shell/rc"
fi