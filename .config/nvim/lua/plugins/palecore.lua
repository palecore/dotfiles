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
		lazy = false,
		init = function()
			vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
			vim.keymap.set({ "n" }, "S", "<Plug>(leap-from-window)")
		end,
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
			{ "<c-h>", function() vim.fn["copilot#Dismiss"]() end, mode = "i", id = "copilot_dismiss" },
			{ "<c-p>", function() vim.fn["copilot#Previous"]() end, mode = "i", id = "copilot_previous" },
			{ "<c-n>", function() vim.fn["copilot#Next"]() end, mode = "i", id = "copilot_next" },
		},
	},
	{
		"olimorris/codecompanion.nvim",
		version = "^18.0.0",
		cmd = {
			"CodeCompanion",
			"CodeCompanionActions",
			"CodeCompanionChat",
			"CodeCompanionCmd",
		},
		keys = {
			{ "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", id = "ai_chat" },
			{ "<leader>aA", "<cmd>CodeCompanionActions<cr>", id = "ai_actions" },
			{ "<leader>Aa", "<cmd>CodeCompanionActions<cr>", id = "ai_actions" },
			{ "<leader>AA", "<cmd>CodeCompanionActions<cr>", id = "ai_actions" },
			{ "<leader>ai", ":CodeCompanion<space>", id = "ai_inline", mode = { "n", "v" } },
			{ "<leader>ac", ":CodeCompanionCmd<space>", id = "ai_cmd" },
		},
		dependencies = {
			"franco-ruggeri/codecompanion-spinner.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/codecompanion-history.nvim", -- session management
		},
		opts = {
			-- [!TIP] to open in the current buffer:
			-- display = { chat = { window = { layout = "buffer" } } },
			diff_view = {
				layout = "inline",
				context_lines = 3,
				show_line_numbers = true,
				highlight_added = "DiffAdd",
				highlight_removed = "DiffDelete",
			},
			interactions = {
				chat = {
					tools = {
						groups = {
							["develop"] = {
								description = "Custom comprehensive skillset for development",
								system_prompt = "You have access to the following tools:"
									.. " fetching webpages,"
									.. " reading, writing and creating files;"
									.. " searching and grepping throughout files; "
									.. " and saving and retrieving conversation memory.",
								tools = {
									"create_file",
									"delete_file",
									"fetch_webpage",
									"file_search",
									"files",
									"grep_search",
									"insert_edit_into_file",
									"memory",
									"read_file",
								},
								opts = {
									collapse_tools = false, -- show tools separately
								},
							},
							["research"] = {
								description = "Custom comprehensive skillset for research",
								system_prompt = "You have access to the following tools:"
									.. " fetching webpages,"
									.. " reading, writing and creating files;"
									.. " searching and grepping throughout files; "
									.. " and saving and retrieving conversation memory.",
								tools = {
									"fetch_webpage",
									"file_search",
									"grep_search",
									"memory",
									"read_file",
								},
								opts = {
									collapse_tools = false, -- show tools separately
								},
							}
						},
					},
				},
			},
			extensions = {
				spinner = {},
				history = {
					enabled = true,
					continue_last_chat = true,
					delete_on_clearing_chat = true,
					keymap = "gh",
					save_chat_keymap = "sc",
					auto_save = false,
					expiration_days = 30, -- clean up archived chat after a month
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
					title_generation_opts = {
						-- use lightweight model to avoid exhausting premium interactions:
						adapter = "copilot",
						model = "gpt-4o",
					},
				},
			},
		},
	},
}
