# vim: set ft=sh sw=2 ts=2 noet:

# Shell settings
# --------------

# enable vi mode:
set -o vi
# 1s timeout on keybinds:
KEYTIMEOUT=1

HISTSIZE=100
SAVEHIST=100
# XDG-compliant sh history:
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/share}/sh_history"
# no duplicates and irrelevant lines in sh history:
HISTCONROL=ignoreboth:erasedups
