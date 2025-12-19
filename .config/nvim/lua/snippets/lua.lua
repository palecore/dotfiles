local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("lua", {
	--
	s({ trig = "shebang", dscr = "Shebang for Lua scripts." }, {
		t("#!/usr/bin/env lua"),
	}),
	--
	s({ trig = "seevar", dscr = "Send a vim notification with a variable being inspected." }, {
		t('vim.notify(vim.inspect { "'),
		f(function(args) return args[1][1] end, { 1 }, {}),
		t('", '),
		i(1),
		t(" })"),
	}),
	s({ trig = "module", dscr = "Module boilerplate." }, {
		t({ "local M = {}", "", "" }),
		i(1),
		t({ "", "", "return M" }),
	}),
	s({ trig = "class", dscr = "Class boilerplate." }, {
		t("local "),
		i(1),
		t({ " = {}" }),
		f(function(a)
			local c = a[1][1]
			return {
				"",
				c .. ".__index = " .. c,
				"",
				"function " .. c .. ":new()",
				"\tlocal o = {}",
				"\treturn setmetatable(o, self)",
				"end",
				"",
				"",
			}
		end, { 1 }, {}),
	}),
})
