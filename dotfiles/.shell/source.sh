#!/bin/sh

source $HOME/.shell/util.sh

safe_source "$HOME/.cargo/env"

# Source OS dependant locations
case $OS in

    # linux
    linux*)
        safe_source /usr/share/autojump/autojump.sh
        ;;

    # Mac OSX
    darwin*)
        safe_source /opt/homebrew/etc/profile.d/autojump.sh
        ;;

    # Cygwin
    cygwin*)
        ;;

    # MinGW
    msys*)
        ;;

    # Other
    *)
        ;;
esac