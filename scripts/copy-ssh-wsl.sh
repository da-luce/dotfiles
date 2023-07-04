#!/bin/bash

## copy ssh keys if running WSL. Optional argument of windows username if
## different than Linux username

[[ $1 = "" ]] && windows_username = $USER || a = $1

if [ -d "/mnt/c/Users/$windows_username/.ssh" ]; then
    cp -a /mnt/c/Users/$windows_username/.ssh/. $HOME/.ssh/
else
    echo "failure: could not find Windows .ssh folder"
fi