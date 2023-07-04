#!/bin/bash

## copy ssh keys if running WSL. Optional argument of windows username if
## different than Linux username

WINDOWS_USERNAME=$1;

if [$WINDOWS_USERNAME == ""]; then
    WINDOWS_USERNAME=$USER
fi

mkdir -p $HOME/.ssh/
sudo chmod 700 $HOME/.ssh/
echo "set $HOME/.ssh/ permissions to 700" ;;

if [ -d "/mnt/c/Users/$WINDOWS_USERNAME/.ssh" ]; then
    cp -a /mnt/c/Users/$WINDOWS_USERNAME/.ssh/. $HOME/.ssh/
    # set correct permissions (ttps://meng6.net/pages/blog/permission_of_.ssh_files/)
    for FILE in $HOME/.ssh/*; do
        case $FILE in
            (*.pub)
                sudo chmod 644 $FILE
                echo "set $FILE permissions to 644" ;;
            (*known_hosts)
                sudo chmod 644 $FILE
                echo "set $FILE permissions to 644" ;;
            (*)
                sudo chmod 600 $FILE
                echo "set $FILE permissions to 600" ;;
        esac
    done
else
    echo "failure: could not find Windows .ssh folder"
fi