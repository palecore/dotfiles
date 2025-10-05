# vim: set ft=sh sw=2 ts=2 noet:

# set up user-local command-line utility variables:
#
: "${EDITOR:=nvim}"
export EDITOR
: "${VISUAL:="$EDITOR"}"
export VISUAL
: "${PAGER:=less}"
export PAGER
: "${SUDOEDIT_CMD:=sudoedit}"
export SUDOEDIT_CMD
: "${SUDO_CMD:=sudo}"
export SUDO_CMD
: "${EXPLORER:=vifm}"
export EXPLORER

