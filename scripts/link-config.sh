#!/bin/bash

# create symlinks from local config files to where each program searchs for its
# respective config 

mkdir -p $HOME/.config/

ln -sfn $HOME/.dotfiles/bashrc $HOME/.bashrc
ln -sfn $HOME/.dotfiles/tmux $HOME/.config/tmux/tmux.conf
# assume we are using version >= 3.1
ln -sfn $HOME/.dotfiles/vim $HOME/.vimrc
ln -sfn $HOME/.dotfiles/starship $HOME/.config/starship.toml
ln -sfn $HOME/.dotfiles/nvim $HOME/.config