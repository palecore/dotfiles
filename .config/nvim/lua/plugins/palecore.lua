---@type LazySpec[]
return {
	{
		"ggandor/leap.nvim",
		keys = {
			{ "s", "<Plug>(leap)", mode = { "n", "x", "o" }, id = "leap" },
			{ "S", "<Plug>(leap-from-window)", mode = { "n" }, id = "leap_from_window" },
		},
		opts = {},
	},
}
