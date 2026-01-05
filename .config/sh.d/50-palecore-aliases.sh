# vim: set ft=sh sw=2 ts=2 noet:

# Aliases
# -------

# misc:
alias sudo='"${SUDO_CMD:-sudo}" ' # allow expanding aliases after sudo
alias s='"${SUDO_CMD:-sudo}" '
alias sub=subsystemctl
alias reboot='"${SUDO_CMD:-sudo}" reboot'
alias elo='"${SUDO_CMD:-sudo}" shutdown -h now' # goodbye in polish style
alias less='less --ignore-case'
alias e='${EDITOR:?}'
alias se='"${SUDOEDIT_CMD:-sudoedit}"'
alias ls='ls --color=auto'
alias pingme='ping archlinux.org' # check internet connection

# filesystem management:
alias f='"${EXPLORER:?filesystem EXPLORER env var not set}"'
# open file explorer here:
alias f.='f .'

# X11:
alias x='startx "${XDG_CONFIG_HOME:-$HOME/.config}/xinitrc"'
alias xd='x dwm'
alias xf='x xfce4'

# tmux:
alias tmux='tmux -T 256,clipboard' # force 256 colors & clipboard support
alias t=tmux
alias ta='tmux attach'

# android termux:
alias termuxssh='ssh -p 8022 -l ${TERMUX_USER+-l "${TERMUX_USER}"}'

# git:
alias G=git\ status
alias GL=git\ log\ --oneline\ --graph

