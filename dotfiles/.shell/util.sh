#!/bin/sh

lowercase()
{
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

safe_source() {
    if [ -f "$1" ]; then
        . "$1"
    else
        echo "WARN: File $1 not found"
    fi
}

retry_command() {
    local cmd="$1"    # The command to execute

    while true; do
        if eval "$cmd"; then
            echo "Command succeeded: $cmd"
            return 0
        else
            echo "Command failed: $cmd"
            echo "What would you like to do?"
            read -p "Enter 'r' to retry or 'q' to quit: " choice
            case $choice in
                [Rr]* )
                    echo "Retrying..."
                    continue
                    ;;
                [Qq]* )
                    echo "Exiting..."
                    return 1
                    ;;
                * )
                    echo "Please enter 'r' or 'q'"
                    ;;
            esac
        fi
    done
}

midway_authenticated() {
    MWAUTHED=$(mcurl --silent --show-error https://midway-auth.amazon.com/api/session-status | jq '.authenticated')
    if [[ "false" == "$MWAUTHED" ]]; then
        return false
    else
        return true
    fi
}