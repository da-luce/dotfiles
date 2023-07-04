#!/bin/bash

## copy ssh keys if running WSL. Optional argument of windows username if
## different than Linux username

WINDOWS_USERNAME=$1;

if [$WINDOWS_USERNAME == ""]; then
    WINDOWS_USERNAME=$USER
fi

if [ -d "/mnt/c/Users/$WINDOWS_USERNAME/.ssh" ]; then
    cp -a /mnt/c/Users/$WINDOWS_USERNAME/.ssh/. $HOME/.ssh/
    # Update permissions
    for FILE in $HOME/.ssh/; do 
        sudo chmod 600 $FILE
    done
else
    echo "failure: could not find Windows .ssh folder"
fi