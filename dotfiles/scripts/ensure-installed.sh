#!/bin/bash

# ensure listed packages are installed
# TODO: add version checking?

packages=(
    curl
    wget
    lua5.3
    default-jre
    python3
    tmux
    fzf
    autojump
    gcc
    vite
    neovim
    libncurses5-dev
    libncursesw5-dev
    nodejs
)

all_installed=true

for package in "${packages[@]}"; do
    dpkg -s "$package" >/dev/null 2>&1 || {
        all_installed=false
        echo "Warning: $package is NOT installed."
    }
done

if all_installed; then
    echo "All packages installed."
else
    echo "Some packages do not appear to be installed."
fi