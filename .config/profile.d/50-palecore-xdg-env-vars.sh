# vim: set ft=sh sw=2 ts=2 noet:

# set up env vars for XDG dirs (expanded with custom ones):
#
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_LIB_HOME="$HOME/.local/lib"
export XDG_SRC_HOME="$HOME/.local/src"
export XDG_STATE_HOME="$HOME/.local/state"
[ -z "${TMPDIR-}" ] || export XDG_RUNTIME_DIR="${TMPDIR-}"

