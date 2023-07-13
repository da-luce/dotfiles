# Reset path (or else it gets longer each time this is sourced)
export PATH=$(getconf PATH)

# HISTORY

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth:erasedups

# append to history file, don't overwrite it
shopt -s histappend

# setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# EDITOR

# Set default editor and visual editor
export EDITOR=$(basename $(command -v nvim || command -v vim))
export VISUAL=${EDITOR}

# COLOR WEIRDNESS

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned off
# by default to not distract the user: the focus in a terminal window should be
# on the output of commands, not on the prompt
force_color_prompt=yes

# ALIASES

alias la='ls -a'

alias f=fzf --preview='head -$LINES {}'

alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'

alias stat='git status'
alias com='git commit -m'

alias windows='cd /mnt/c/Users/sixsa/'
alias dot='cd $HOME/.dotfiles'

# MISC

# source autojump
. /usr/share/autojump/autojump.sh

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Add to path so that starship can run
export PATH="/usr/local/bin:$PATH"

# fancy prompt with starship
eval "$(starship init bash)"