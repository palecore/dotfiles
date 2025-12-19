local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.add_snippets("sh", {
	s(
		{ trig = "posixheader", dscr = "POSIX /bin/sh header" },
		t({
			"#!/bin/sh",
			"# shellcheck shell=sh",
			"set -eu",
		})
	),
	s(
		{ trig = "bashheader", dscr = "POSIX bash entrypoint header" },
		t({
			"#!/bin/sh",
			"# shellcheck shell=bash",
			'[ "${BASH_VERSION-}" ] || exec bash "$0" "$@"',
			"set -euo pipefail",
		})
	),
})
