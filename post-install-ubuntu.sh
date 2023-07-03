#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root" 
   	exit 1
fi

# update and upgrade
apt-get update -y
apt-get upgrade -y

## PACKAGES 
apt install curl -y
apt install wget
apt install lua5.3 -y
apt install tmux
apt install fzf
apt install autojump
apt-get install gcc -y

## CURL APPS
curl -sS https://starship.rs/install.sh | sh

## BREW APPS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## WGET APPS
# Conda
wget https://repo.continuum.io/archive/Anaconda3-5.2.0-Linux-x86_64.sh
/bin/bash Anaconda3-5.2.0-Linux-x86_64.sh

## LIBRARIES
apt-get install libncurses5-dev libncursesw5-dev

## SIM LINKS
ln -s $HOME/.dotfiles/bashrc $HOME/.bashrc
ln -s $HOME/.dotfiles/tmux $HOME/.tmux.conf
ln -s $HOME/.dotfiles/vim $HOME/.vimrc
ln -s $HOME/.dotfiles/starship $HOME/.config/starship.toml

## MISC
# copy ssh keys if running as vm/WSL
if [ -d "/mnt/c/Users/sixsa/.ssh" ]; then
    cp -a /mnt/c/Users/sixsa/.ssh/. $HOME/.ssh/
else
    echo "warning: no ssh keys copied"
fi

## System Update and Upgrade
apt update
apt install --fix-missing -y
apt upgrade --allow-downgrades -y
apt full-upgrade --allow-downgrades -y

## System Clean Up
apt install -f
apt autoremove -y
apt autoclean
apt clean