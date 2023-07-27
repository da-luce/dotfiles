#!/bin/bash
# Copy ssh keys from host to client

host_ssh=$1;    # host .ssh directory
client_ssh=$2;  # client .ssh directory

mkdir -p client_ssh
sudo chmod 700 client_ssh
echo "set  $client_ssh permissions to 700"

if [ -d host_ssh ]; then
    cp -a host_ssh client_ssh
    # set correct permissions
    # https://meng6.net/pages/blog/permission_of_.ssh_files/
    for FILE in client_ssh*; do
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
    echo "failure: could not find host folder '$host_ssh'"
fi
