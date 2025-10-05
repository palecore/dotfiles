# vim: set ft=sh sw=2 ts=2 noet:

# check important system environment variables (warn on absence):
#
[ -n "${TERM-}" ] \
	|| echo 'WARN: TERM not set; better set it system-wide' >&2
[ -n "${TMPDIR-}" ] \
	|| echo 'WARN: TMPDIR not set; better set it system-wide' >&2
