# vim: set ft=bash sw=2 ts=2 noet:

# __git_ps1 wrapper to not fail if git is not installed
__plc_git_ps1() {
	__git_ps1 "$@" 2> /dev/null || :
}

# set up prompt: '<username>@<hostname> <cwd>'...
PS1='\[\e[32m\]\u\[\e[93m\]@\[\e[33m\]\h\[\e[49;34m\] \w'
# ...' (<git-branch>)'...
PS1+='\[\e[35m\]$(__plc_git_ps1 " (%s)")'
# ...' % '
PS1+='\[\e[49;36m\] %\[\e[97m\] '

PS0='\e[2 q'

# misc interactive settings:
bind -m vi-command 'C-l:clear-screen'
bind -m vi-insert 'C-l:clear-screen'
bind 'set show-mode-in-prompt on'
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'
bind 'set keyseq-timeout 50'
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set skip-completed-text on'
bind 'set visible-stats on'
