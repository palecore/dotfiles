local function gh_buf_toggle() return require("palecore.gh-copilot").buf_toggle() end
local function gh_global_disable()
	return require("palecore.gh-copilot").global_disable()
end

---@type LazySpec[]
return {
	{
		"L3MON4D3/LuaSnip",
		config = function(_, opts)
			require("luasnip").setup(opts)
			-- load filetype-specific snippets from snippets/ dir hierarchy:
			require("luasnip.loaders.from_lua").load({
				paths = vim.fn.stdpath("config") .. "/lua/snippets",
			})
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
	{
		"github/copilot.vim",
		cmd = "Copilot",
		init = function()
			-- by default, disable copilot for all filetypes:
			vim.g.copilot_filetypes = { ["*"] = false }
			vim.g.copilot_no_tab_map = true
		end,
		keys = {
			-- only enable it explicitly per buffer:
			{ "<leader>ta", gh_buf_toggle, id = "toggle_ai", desc = "Toggle GenAI" },
			{ "<leader>tA", gh_global_disable, id = "disable_ai1", desc = "Disable GenAI" },
			{ "<leader>Ta", gh_global_disable, id = "disable_ai2", desc = "Disable GenAI" },
			{ "<leader>TA", gh_global_disable, id = "disable_ai3", desc = "Disable GenAI" },
			{
				"<c-l>",
				function() return vim.fn["copilot#Accept"]("\r") end,
				expr = true,
				replace_keycodes = false,
				mode = "i",
				id = "copilot_accept",
			},
			{ "<c-h>", "<Plug>(copilot-dismiss)", mode = "i", id = "copilot_dismiss" },
			{ "<c-p>", "<Plug>(copilot-previous)", mode = "i", id = "copilot_previous" },
			{ "<c-n>", "<Plug>(copilot-next)", mode = "i", id = "copilot_next" },
		},
	},
	{
		"olimorris/codecompanion.nvim",
		version = "^18.0.0",
		cmd = { "CodeCompanion", "CodeCompanionChat" },
		keys = {
			{ "<leader>aa", "<cmd>CodeCompanionChat<cr>", id = "ai_chat" },
			{ "<leader>ai", ":CodeCompanion<space>", id = "ai_inline" },
			{ "<leader>ac", ":CodeCompanionCmd<space>", id = "ai_cmd" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/codecompanion-history.nvim", -- session management
		},
		opts = {
			extensions = {
				history = {
					enabled = true,
					keymap = "gh",
					save_chat_keymap = "sc",
					auto_save = false,
					expiration_days = 30, -- clean up archived chat after a month
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
				},
			},
		},
	},
}
