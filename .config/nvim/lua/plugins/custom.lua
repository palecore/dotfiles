---My custom neovim configuration.

---@type LazySpec[]
return {
	{ "tpope/vim-eunuch" },
	{ "tpope/vim-speeddating" },
	{ "tpope/vim-surround" },
	{
		"tpope/vim-dispatch",
		keys = {
			{ "<leader>dd", "<cmd>Delete<cr>", id = "delete_this" },
		},
	},
	{
		-- Convenient commenting out of text blocks
		"preservim/nerdcommenter",
		keys = {
			{
				"<leader>/",
				"<Plug>NERDCommenterToggle",
				mode = { "n", "v" },
				id = "comment_toggle",
			},
		},
		init = function()
			vim.g.NERDSpaceDelims = 1
			vim.g.NERDCreateDefaultMappings = 0
		end,
	},
	{
		-- My custom colorscheme based on monokai
		name = "custom-colorscheme",
		dir = "/dev/null",
		dependencies = "sickill/vim-monokai", -- basis colorscheme
		config = function()
			vim.cmd.colorscheme("monokai")
			require("custom-helpers").on_lazy_done(function()
				vim.api.nvim_set_hl(0, "Identifier", { fg = "#7070F0" })
				vim.api.nvim_set_hl(0, "Operator", { fg = "#f8f8f2", bold = true })
				vim.api.nvim_set_hl(0, "Constant", { fg = "#ef5939" })
				vim.api.nvim_set_hl(0, "StorageClass", { fg = "#66d9ef" })
				vim.api.nvim_set_hl(0, "Special", { fg = "#f92672", bold = true })
				vim.api.nvim_set_hl(0, "Label", { fg = "#fd971f", bold = true })
			end)
		end,
	},
	-- Enhanced status line
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			local custom_branch = { "branch", icon = "|-" }
			local custom_diagnostics = {
				"diagnostics",
				symbols = { error = "E", warn = "W", info = "I", hint = "H" },
			}
			local custom_fileformat = {
				"fileformat",
				symbols = { unix = "\\n", dos = "\\r\\n", mac = "\\r" },
			}
			require("lualine").setup({
				options = {
					section_separators = { left = "", right = "" },
					component_separators = { left = "|", right = "|" },
					globalstatus = false,
				},
				sections = {
					lualine_b = { custom_branch, "diff", custom_diagnostics },
					lualine_x = { "encoding" },
					lualine_y = { custom_fileformat, "filetype" },
					lualine_z = { "progress", "location" },
				},
			})
		end,
	},
	{
		-- General, miscellaneous lightweight settings
		name = "custom-general",
		dir = "/dev/null",
		config = function()
			-- helper functions

			local lazy_fn = require("custom-helpers").lazy_fn
			local nvim_cmd = require("custom-helpers").nvim_cmd

			-- General Options
			-- ---------------

			vim.o.compatible = false

			vim.o.number = true
			vim.o.relativenumber = true

			vim.o.ignorecase = true
			vim.o.smartcase = true
			vim.o.hlsearch = false

			vim.o.splitbelow = true
			vim.o.splitright = true

			-- Scroll offset of 3
			vim.o.scrolloff = 3
			vim.o.joinspaces = false

			vim.opt.completeopt = { "menu", "menuone", "noselect" }

			-- Default indentation - 4 spaces
			vim.o.tabstop = 4
			vim.o.shiftwidth = 4
			vim.o.expandtab = true

			-- Text Wrapping:
			-- Show whitespace characters:
			vim.o.list = true
			vim.opt.listchars = "extends:»,precedes:…,tab:¦ ,trail:…"
			-- Other cool glyphs: ·…»¬→˲¦
			vim.o.wrap = false
			vim.o.textwidth = 80
			vim.opt.colorcolumn = { 80 }

			vim.o.breakat = " {([:,."
			vim.o.showbreak = "↳·"
			vim.o.linebreak = true
			vim.o.breakindent = true
			vim.o.breakindentopt = "list:-1"

			-- rely on syntax for folding by default:
			vim.o.foldmethod = "syntax"
			vim.o.foldlevel = 3

			vim.o.backup = false
			vim.o.backupdir = vim.fn.stdpath("state") .. "/backup"
			vim.opt.diffopt = {
				"vertical",
				"filler",
				"foldcolumn:1",
				"indent-heuristic",
				"algorithm:patience",
				"internal",
			}

			vim.o.clipboard = "unnamedplus"

			-- syntax highlighting:
			vim.o.termguicolors = true

			vim.g.monokai_term_italic = 1
			vim.g.monokai_gui_italic = 1
			vim.g.java_highlight_all = 1
			vim.g.java_highlight_functions = 1
			-- Shape of the cursor
			vim.opt.guicursor = table.concat({ "n-v-sm:block", "i-c-ci-ve:ver25", "r-cr-o:hor20" }, ",")
			-- netrw:
			vim.g.netrw_banner = 0
			vim.g.netrw_liststyle = 3
			vim.g.netrw_winsize = 32
			vim.g.netrw_localrmdiropt = "rf"
			--
			-- General Keybindings
			-- -------------------

			-- Define helper functions:
			local function diagno_next() vim.diagnostic.jump({ count = 0 + 1, float = true }) end
			local function cd_to_here()
				nvim_cmd({ "cd", "%:h" })
				print(nvim_cmd("pwd"))
			end
			local function paste_strfdate() vim.fn.strftime("%Y-%m-%d") end
			local function paste_strftime() vim.fn.strftime("%H:%M") end
			local function paste_curfile() vim.fn.expand("%") end
			local function diagno_prev() vim.diagnostic.jump({ count = 0 - 1, float = true }) end
			local function diagno_list() vim.diagnostic.setloclist({}) end
			---Jump to the first item only if there is just only one item.
			---Otherwise, open quickfix list (but don't switch to it).
			---@param options vim.lsp.LocationOpts.OnList
			local function fill_qf_jump_only_if_first(options)
				vim.fn.setqflist(options.items, " ")
				if #options.items == 1 then
					vim.cmd.cfirst()
				else
					local cur_win = vim.api.nvim_get_current_win()
					vim.cmd.copen()
					vim.api.nvim_set_current_win(cur_win)
				end
			end
			local function go_to_definition()
				return vim.lsp.buf.definition({ reuse_win = true, on_list = fill_qf_jump_only_if_first })
			end
			local function go_to_typedef()
				return vim.lsp.buf.definition({ reuse_win = true, on_list = fill_qf_jump_only_if_first })
			end
			local function go_to_references()
				return vim.lsp.buf.references(
					{ includeDeclaration = false },
					{ on_list = fill_qf_jump_only_if_first }
				)
			end
			local rename_symbol = vim.lsp.buf.rename
			local code_actions = vim.lsp.buf.code_action
			local function window_close() vim.api.nvim_buf_delete(0, { force = true }) end
			local custom_actions = require("custom-actions")

			-- Define actual keybindings:

			-- Apply (C)ode (F)ormatting:
			vim.keymap.set({ "n", "v" }, "<leader>cf", custom_actions.format)
			-- Jump to next (D)iagnostic:
			vim.keymap.set("n", "]d", diagno_next)
			-- Jump to previous (D)iagnostic:
			vim.keymap.set("n", "[d", diagno_prev)
			-- Show (D)iagnostic list:
			vim.keymap.set("n", "<leader>qq", diagno_list)
			vim.keymap.set("n", "<leader>rn", rename_symbol)
			vim.keymap.set("n", "<leader>ca", code_actions)
			vim.keymap.set("n", "gd", go_to_definition)
			vim.keymap.set("n", "gD", go_to_typedef)
			-- (G)o to (R)eferences:
			vim.keymap.set("n", "gr", go_to_references)
			-- Clear unnecessary default `gr...` keybindings:
			vim.keymap.del("n", "gri")
			vim.keymap.del("n", "gra")
			vim.keymap.del("n", "grn")
			vim.keymap.del("n", "grr")

			-- (C)hange (D)irectory to that of current file's:
			vim.keymap.set("n", "<leader>cd", cd_to_here)
			-- Open terminal, the e(X)ecution environment:
			vim.keymap.set("n", "<leader>x", lazy_fn(nvim_cmd, "terminal"))
			-- (R)-egister-like-paste default clipboard while in insert mode:
			vim.keymap.set("i", "<c-r><c-r>", "<c-r>+")
			-- (R)egister-like-paste current (D)ate
			-- (precision: days; standard: rfc-3339):
			vim.keymap.set("i", "<c-r><c-d>", paste_strfdate, { expr = true })
			-- (R)egister-like-paste current (T)ime
			-- (precision: minutes; standard: rfc-3339):
			vim.keymap.set("i", "<c-r><c-t>", paste_strftime, { expr = true })
			-- (R)egister-like-paste current name/path of the current (F)ile:
			vim.keymap.set("i", "<c-r><c-f>", paste_curfile, { expr = true, desc = "paste_curfile" })
			-- (G)it-(A)dd current file:
			vim.keymap.set("n", "<leader>ga", "<cmd>Git add %<cr>")
			--(W)indow: (C)lose it for good:
			vim.keymap.set("n", "<C-W>C", window_close)

			-- Go through the quickfix list without entering command mode:
			vim.keymap.set("n", "<leader>cn", "<cmd>cnext<cr>", { desc = "next quickfix item" })
			vim.keymap.set("n", "<leader>cN", "<cmd>clast<cr>", { desc = "last quickfix item" })
			vim.keymap.set("n", "<leader>CN", "<cmd>clast<cr>", { desc = "last quickfix item" })
			vim.keymap.set("n", "<leader>cp", "<cmd>cprevious<cr>", { desc = "previous quickfix item" })
			vim.keymap.set("n", "<leader>cP", "<cmd>cfirst<cr>", { desc = "first quickfix item" })
			vim.keymap.set("n", "<leader>CP", "<cmd>cfirst<cr>", { desc = "first quickfix item" })
			vim.keymap.set("n", "<leader>co", "<cmd>copen<cr>", { desc = "open quickfix itemlist" })
			vim.keymap.set("n", "<leader>cc", "<cmd>cclose<cr>", { desc = "close quickfix itemlist" })
		end,
	},
}
