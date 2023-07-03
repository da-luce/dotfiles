#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root" 
   	exit 1
fi

# update and upgrade
apt-get update -y
apt-get upgrade -y

## PACKAGES 
apt install -y curl
apt install -y wget
apt install -y lua5.3
apt install -y default-jre
apt install -y python3
apt install -y tmux
apt install -y htop
apt install -y fzf
apt install -y autojump
apt-get install -y gcc
apt-get install -y vite

# PPA's apps from other sources
curl -sS https://starship.rs/install.sh | bash                  # starship
curl -fsSL https://deb.nodesource.com/setup_18.x | -E bash -    # node.js
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash # homebrew

# install other sources
apt install -y nodejs
npm install -g npm@latest # ensure latest version of npm was installed

## WGET APPS
# Conda
wget https://repo.continuum.io/archive/Anaconda3-5.2.0-Linux-x86_64.sh
/bin/bash Anaconda3-5.2.0-Linux-x86_64.sh

## LIBRARIES
apt-get install libncurses5-dev libncursesw5-dev

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