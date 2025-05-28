#!/bin/sh

alias l='ls --color=auto'
alias s='git status'
alias v='nvim'
alias f=fzf --preview='head -$LINES {}'
alias c='git commit -m'

alias la='ls -la --color=auto'
alias ls='ls -l --color=auto'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ece='source $HOME/.dotfiles/scripts/ece.sh; connect'
alias vpn='source $HOME/.dotfiles/scripts/ece.sh; connect_to_vpn'
alias pdf='pandoc -f markdown-implicit_figures --columns=80 --wrap=auto -o'
alias dot='cd $HOME/.dotfiles'
alias nav='docker-compose run --rm nav'
alias autobike='docker run -it --rm -v "$(pwd):/usr/app" --user root --env DISPLAY=host.docker.internal:0 autobike'

# OS specific aliases
case $OS in

    # linux
    linux*)

        case $KERNEL in
            # WSL
            *microsoft*)
                alias windows='cd /mnt/c/Users/sixsa/';;

             # Normal, good ol' linux
            *)
                : ;;
        esac
        ;;

    # Mac OSX
    darwin*)
        alias vm="multipass"
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

