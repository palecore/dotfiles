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
alias termuxssh='ssh -p 8022'

# git:
alias G=git\ status
alias GL=git\ log\ --oneline\ --graph

# unisync MAIN OTHER
#
# Syncs two directories using unison, preferring changes from OTHER.
unisync()
(
	main="${1:?}"
	other="${2:?}"
	unison \
		-batch -perms 0 -times -copyonconflict \
		-root "$other" \
		-root "$main" \
		-prefer "$other" \
		;
)

# Unison Helpers
# --------------

# unisyncd MAIN OTHER
#
# Like unisync, but in watch mode - continuously syncs changes as a daemon.
unisyncd()
(
	main="${1:?}"
	other="${2:?}"
	unison \
		-batch -perms 0 -times -copyonconflict \
		-repeat watch \
		-root "$other" \
		-root "$main" \
		-prefer "$other" \
		;
)
