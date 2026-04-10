---@type LazySpec
return {
	"saghen/blink.cmp",
	version = "1.2.0",
	dependencies = {
		"moyiz/blink-emoji.nvim", -- for emoji completion
		"L3MON4D3/LuaSnip", -- for Lua snippets
	},
	config = function()
		local function snip_forward_if_active(cmp)
			return cmp.snippet_active() and cmp.snippet_forward() or nil
		end
		local function snip_backward_if_active(cmp)
			return cmp.snippet_active() and cmp.snippet_backward() or nil
		end
		require("blink.cmp").setup({ ---@type blink.cmp.Config
			keymap = {
				["<CR>"] = { "accept", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<Tab>"] = { snip_forward_if_active, "fallback" },
				["<S-Tab>"] = { snip_backward_if_active, "fallback" },
				["<C-l>"] = { "scroll_documentation_down", "show_documentation", "fallback_to_mappings" },
				["<C-h>"] = { "hide_documentation", "fallback_to_mappings" },
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
				default = { "lsp", "path", "snippets", "emoji", "buffer" },
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
			snippets = { preset = "luasnip" },
		})
		-- Highlight kinds of menu items like keywords:
		require("custom-helpers").on_lazy_done(
			function() vim.api.nvim_set_hl(0, "BlinkCmpKind", { link = "Keyword" }) end
		)
	end,
}
