---@type LazySpec[]
return {
	{
		"L3MON4D3/LuaSnip",
		config = function(_, opts)
			require("luasnip").setup(opts)
		end,
	},

	{
		"ggandor/leap.nvim",
		keys = {
			{ "s", "<Plug>(leap)", mode = { "n", "x", "o" }, id = "leap" },
			{ "S", "<Plug>(leap-from-window)", mode = { "n" }, id = "leap_from_window" },
		},
		opts = {},
	},
}
