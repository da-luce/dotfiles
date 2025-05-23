#!/bin/bash

# create symlinks from local config files to where each program searchs for its
# respective config 

mkdir -p $HOME/.shell/
mkdir -p $HOME/.config/
mkdir -p $HOME/.config/tmux/
mkdir -p $HOME/.config/wezterm/

# Shell files
ln -sfn $HOME/.dotfiles/shell/profile $HOME/.profile
ln -sfn $HOME/.dotfiles/shell/bashrc $HOME/.bashrc
ln -sfn $HOME/.dotfiles/shell/yzshrc $HOME/.zshrc
ln -sfn $HOME/.dotfiles/shell/rc $HOME/.shell/rc
ln -sfn $HOME/.dotfiles/shell/alias $HOME/.shell/alias
ln -sfn $HOME/.dotfiles/shell/source $HOME/.shell/source
ln -sfn $HOME/.dotfiles/shell/path $HOME/.shell/path

# Program files
ln -sfn $HOME/.dotfiles/tmux $HOME/.tmux.conf
ln -sfn $HOME/.dotfiles/vim $HOME/.vimrc
ln -sfn $HOME/.dotfiles/starship $HOME/.config/starship.toml
ln -sfn $HOME/.dotfiles/wezterm $HOME/.config/wezterm/wezterm.lua

ln -sfn $HOME/.dotfiles/nvim $HOME/.config