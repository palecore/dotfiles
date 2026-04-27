local function gh_buf_toggle() return require("palecore.gh-copilot").buf_toggle() end
local function gh_global_disable() return require("palecore.gh-copilot").global_disable() end

local my_fav_models = {
	"claude-haiku-4.5",
	"claude-opus-4.6",
	"claude-sonnet-4.6",
	"gpt-4.1",
	"gpt-5-mini",
}

--- @type string Caveman skill prompt, distilled from JuliusBrussee/caveman (MIT) SKILL.md.
local caveman_prompt = [[
You are now in CAVEMAN MODE. Respond terse like smart caveman.
All technical substance stay. Only fluff die.

PERSISTENCE
- Active every response. No revert after many turns. No filler drift.
- Stay active if unsure. Off only when user says "stop caveman" or "no caveman" or "caveman off".

RULES
- Drop articles (a/an/the).
- Drop filler (just/really/basically/actually/simply).
- Drop pleasantries (sure/certainly/of course/happy to).
- Drop hedging.
- Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for").
- Technical terms exact. Code blocks unchanged. Errors quoted exact.
- Pattern: "[thing] [action] [reason]. [next step]."

NOT: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
YES: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

INTENSITY: full (default)
- Drop articles, fragments OK, short synonyms. Classic caveman.
- User may switch with "lite" (no filler/hedging, keep articles + grammar)
  or "ultra" (abbreviate DB/auth/config/req/res/fn/impl, strip conjunctions,
  arrows for causality X → Y, one word when one word enough).

AUTO-CLARITY (drop caveman temporarily for):
- Security warnings.
- Irreversible action confirmations.
- Multi-step sequences where fragment order risks misread.
- User asks to clarify or repeats question.
Resume caveman after clear part done.

BOUNDARIES
- Code, commit messages, PR descriptions: write normal English.
- Level persists until changed or session end.

Example — "Why React component re-render?"
- full: "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."
- ultra: "Inline obj prop → new ref → re-render. `useMemo`."

Example — "Explain database connection pooling."
- full: "Pool reuse open DB connections. No new connection per request. Skip handshake overhead."
- ultra: "Pool = reuse DB conn. Skip handshake → fast under load."

Acknowledge silently. Apply from next reply.
]]

local caveman_slash_command = {
	description = "Talk like caveman (token-saving system prompt)",
	---@param chat CodeCompanion.Chat
	callback = function(chat)
		local id = "<caveman:full>"
		-- Idempotent: skip if already added in this chat
		for _, item in ipairs(chat.context_items or {}) do
			if item.id == id then
				return vim.notify(
					"Caveman mode already on.",
					vim.log.levels.INFO,
					{ title = "CodeCompanion" }
				)
			end
		end
		chat:add_context(
			{ role = "system", content = caveman_prompt },
			"caveman",
			id,
			{ visible = true, context_opts = { visible = true } }
		)
	end,
	opts = {
		contains_code = false,
	},
}

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
			vim.keymap.set("i", "<c-l>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
				desc = "Copilot: Accept with newline",
			})
			vim.keymap.set("i", "<c-h>", "<Plug>(copilot-dismiss)", { desc = "Copilot: Dismiss" })
			vim.keymap.set("i", "<c-p>", "<Plug>(copilot-previous)", { desc = "Copilot: Previous" })
			vim.keymap.set("i", "<c-n>", "<Plug>(copilot-next)", { desc = "Copilot: Next" })
		end,
		keys = {
			-- only enable it explicitly per buffer:
			{ "<leader>ta", gh_buf_toggle, id = "toggle_ai", desc = "Toggle GenAI" },
			{ "<leader>tA", gh_global_disable, id = "disable_ai1", desc = "Disable GenAI" },
			{ "<leader>Ta", gh_global_disable, id = "disable_ai2", desc = "Disable GenAI" },
			{ "<leader>TA", gh_global_disable, id = "disable_ai3", desc = "Disable GenAI" },
		},
	},
	{
		"olimorris/codecompanion.nvim",
		version = "^19.0.0",
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
			{
				"<leader>ai",
				":CodeCompanion<space>#{chat}<space>#{buffer}<space>",
				id = "ai_inline",
				mode = { "n", "v" },
			},
			{ "<leader>ac", ":CodeCompanionCmd<space>", id = "ai_cmd" },
		},
		dependencies = {
			"franco-ruggeri/codecompanion-spinner.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/codecompanion-history.nvim", -- session management
		},
		init = function()
			vim.g.codecompanion_nvim_use_memory = false
			vim.g.codecompanion_nvim_open_in_curr_win = false
		end,
		config = function()
			require("codecompanion").setup({
				-- [!TIP] set `g:codecompanion_nvim_open_in_curr_buf` to `true`
				-- to open CodeCompanion Chat window in the current window:
				display = (vim.g.codecompanion_nvim_open_in_curr_win and {
					chat = { window = { layout = "buffer" } },
				} or {}),
				diff_view = {
					layout = "inline",
					context_lines = 3,
					show_line_numbers = true,
					highlight_added = "DiffAdd",
					highlight_removed = "DiffDelete",
				},
				adapters = {
					http = {
						copilot_pro = function()
							return require("codecompanion.adapters").extend("copilot", {
								schema = { model = { default = "claude-opus-4.6", choices = my_fav_models } },
							})
						end,
						copilot_mid = function()
							return require("codecompanion.adapters").extend("copilot", {
								schema = { model = { default = "claude-sonnet-4.6", choices = my_fav_models } },
							})
						end,
						copilot_lite = function()
							return require("codecompanion.adapters").extend("copilot", {
								schema = { model = { default = "claude-haiku-4.5", choices = my_fav_models } },
							})
						end,
						copilot_free = function()
							return require("codecompanion.adapters").extend("copilot", {
								schema = { model = { default = "gpt-4.1", choices = my_fav_models } },
							})
						end,
					},
				},
				interactions = {
					chat = {
						adapter = {
							name = "copilot",
							model = "claude-sonnet-4.6",
						},
						slash_commands = {
							caveman = caveman_slash_command,
						},
						tools = {
							groups = {
								["develop"] = {
									description = "Custom comprehensive skillset for development",
									system_prompt = "You have access to the following tools:"
										.. " reading, searching and grepping through local files;"
										.. " writing and creating local files;"
										.. (vim.g.codecompanion_nvim_use_memory and " saving and retrieving conversation memory;" or "")
										.. " and fetching webpages.",
									tools = {
										"create_file",
										"delete_file",
										"fetch_webpage",
										"file_search",
										"files",
										"grep_search",
										"insert_edit_into_file",
										"read_file",
										vim.g.codecompanion_nvim_use_memory and "memory" or nil,
									},
									opts = {
										collapse_tools = false, -- show tools separately
									},
								},
								["research"] = {
									description = "Custom comprehensive skillset for research",
									system_prompt = "You have access to the following tools:"
										.. " reading, searching and grepping through local files;"
										.. (vim.g.codecompanion_nvim_use_memory and " saving and retrieving conversation memory;" or "")
										.. " and fetching webpages.",
									tools = {
										"fetch_webpage",
										"file_search",
										"grep_search",
										"read_file",
										vim.g.codecompanion_nvim_use_memory and "memory" or nil,
									},
									opts = {
										collapse_tools = false, -- show tools separately
									},
								},
							},
						},
					},
					inline = {
						adapter = {
							name = "copilot",
							model = "claude-sonnet-4.6",
						},
					},
				},
				extensions = {
					spinner = {},
					history = {
						enabled = true,
						opts = {
							delete_on_clearing_chat = true,
							dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
							title_generation_opts = {
								-- use lightweight model to avoid exhausting premium interactions:
								adapter = "copilot",
								model = "gpt-4o",
								-- refresh before and after the first prompt so that user prompt is considered:
								refresh_every_n_prompts = 1,
								max_refreshes = 2,
							},
						},
					},
				},
			})
		end,
	},
}
