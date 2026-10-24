# vim: set ft=sh sw=2 ts=2 noet:

# Shell settings
# --------------

# enable vi mode:
set -o vi
# 1s timeout on keybinds:
KEYTIMEOUT=1

# shell command history:
HISTSIZE=1000 # sh in-session-memory history size
HISTFILESIZE=1000 # sh session-external history file size
SAVEHIST=1000 # zsh
# XDG-compliant sh history:
HISTFILE="$XDG_STATE_HOME/sh_history"
# no duplicates and irrelevant lines in sh history:
HISTCONROL=ignoreboth:erasedups
HISTIGNORE=
