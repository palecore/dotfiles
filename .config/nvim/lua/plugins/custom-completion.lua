---@type LazySpec
return {
	"saghen/blink.cmp",
	version = "1.2.0",
	dependencies = {
		"moyiz/blink-emoji.nvim", -- for emoji completion
	},
	config = function()
		require("blink.cmp").setup({ ---@type blink.cmp.Config
			keymap = {
				["<CR>"] = { "accept", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
			},
			cmdline = {
				keymap = {
					["<CR>"] = { "accept_and_enter", "fallback" },
					["<C-e>"] = { "hide", "fallback" },
				},
				completion = {
					list = { selection = { preselect = false } },
					menu = { auto_show = true },
				},
			},
			completion = {
				menu = {
					draw = {
						treesitter = { "lsp" },
						columns = {
							{ "label", "label_description", gap = 1 },
							{ "kind" },
						},
					},
				},
				documentation = { auto_show = true },
				ghost_text = { enabled = true },
			},
			sources = {
				default = { "emoji", "lsp", "path", "snippets", "buffer" },
				providers = {
					emoji = {
						module = "blink-emoji",
						name = "Emoji",
						score_offset = 15,
						opts = { insert = true },
					},
				},
			},
			signature = { enabled = true },
		})
		-- Highlight kinds of menu items like keywords:
		require("custom-helpers").on_lazy_done(
			function() vim.api.nvim_set_hl(0, "BlinkCmpKind", { link = "Keyword" }) end
		)
	end,
}
