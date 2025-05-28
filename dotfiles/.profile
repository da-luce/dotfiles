#!/bin/sh

# ~/.profile: executed by the command interpreter for login shells.

# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.
# Note, however, that we will have a ~/.bash_profile and it will simply source
# this file as a matter of course.

source $HOME/.shell/util.sh

# Environment variables

ENV="$HOME/.shell/rc";                                      export ENV      # shell init
EDITOR=$(basename "$(command -v nvim || command -v vim)");  export EDITOR   # Editor
VISUAL=EDITOR;                                              export VISUAL   # Visual editor
BASH_SILENCE_DEPRECATION_WARNING=1;                         export BASH_SILENCE_DEPRECATION_WARNING # Silence apple zsh message
XDG_CONFIG_HOME="$HOME/.config";                            export XDG_CONFIG_HOME
DOTFILES="$HOME/.dotfiles/";                                export DOTFILES
TERM="xterm-256color";                                      export TERM

# get os info
OS=$(lowercase "$(uname)");                                 export OS
KERNEL=$(lowercase "$(uname -r)");                          export KERNEL
MACH=$(lowercase "$(uname -m)");                            export MACH

# https://superuser.com/questions/703415/why-do-people-source-bash-profile-from-bashrc-instead-of-the-other-way-round
safe_source "$HOME/.bashrc"
