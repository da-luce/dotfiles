#!/bin/bash

# create symlinks from local config files to where each program searchs for its
# respective config 

mkdir -p $HOME/.config/
mkdir -p $HOME/.config/tmux/

ln -sfn $HOME/.dotfiles/bashrc $HOME/.bashrc
ln -sfn $HOME/.dotfiles/tmux $HOME/.tmux.conf
ln -sfn $HOME/.dotfiles/vim $HOME/.vimrc
ln -sfn $HOME/.dotfiles/starship $HOME/.config/starship.toml
ln -sfn $HOME/.dotfiles/nvim $HOME/.config