# Set prefix to Ctrl-Space instead of Ctrl-b
unbind C-b
set -g prefix C-Space
bind Space send-prefix

# Split windows using | and -
unbind '"'
unbind %
bind | split-window -h
bind - split-window -v

# Mouse mode
set -g mouse on