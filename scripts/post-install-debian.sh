#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root" 
   	exit 1
fi

# update and upgrade
apt-get update -y
apt-get upgrade -y

# Apps
apt install -y curl
apt install -y wget
apt install -y lua5.3
apt install -y default-jre
apt install -y python3
apt install -y tmux
apt install -y htop
apt install -y fzf
apt install -y autojump
apt install -y software-properties-common
apt-get install -y gcc
apt-get install -y vite

# Launchpad PPAs
add-apt-repository ppa:neovim-ppa/stable

## System update
apt update

# install launchpad apps
apt install -y neovim

# Other PPAs
curl -sS https://starship.rs/install.sh | sh                 	# starship
curl -fsSL https://deb.nodesource.com/setup_18.x | sh			# node.js
curl https://repo.continuum.io/archive/Anaconda3-5.2.0-Linux-x86_64.sh | sh # Conda

# install other apps
apt-get install -y nodejs
npm install -g npm@latest # ensure latest version of npm was installed

apt-get install -y libncurses5-dev libncursesw5-dev

## System Update and Upgrade
apt update
apt install -y --fix-missing
apt upgrade -y --allow-downgrades
apt full-upgrade -y --allow-downgrades

## System Clean Up
apt install -f
apt autoremove -y
apt autoclean
apt clean