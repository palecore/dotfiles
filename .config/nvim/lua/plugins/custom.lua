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
		"numToStr/Comment.nvim",
		opts = {},
	},
	{
		-- My custom colorscheme based on monokai
		"sickill/vim-monokai",
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

			-- General, Miscellaneous Lightweight Settings
			-- -------------------------------------------
			-- NOTE: These are not lualine-related.

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
			local default_text_width = 80
			vim.o.textwidth = default_text_width
			vim.o.colorcolumn = tostring(default_text_width)

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

			local action_store = require("custom-action-store")

			-- Define helper functions:
			local function diagno_next() vim.diagnostic.jump({ count = 0 + 1, float = true }) end
			local function cd_to_here()
				nvim_cmd({ "cd", "%:h" })
				print(nvim_cmd("pwd"))
			end
			local function paste_strfdate() return vim.fn.strftime("%Y-%m-%d") end
			local function paste_strftime() return vim.fn.strftime("%H:%M") end
			local function paste_curfile() return vim.fn.expand("%") end
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
			action_store.set_action("goto_defs", go_to_definition)
			local function goto_defs_action() action_store.exec_action("goto_defs") end

			local function go_to_typedef()
				return vim.lsp.buf.definition({ reuse_win = true, on_list = fill_qf_jump_only_if_first })
			end
			action_store.set_action("goto_typedefs", go_to_typedef)
			local function goto_typedefs_action() action_store.exec_action("goto_typedefs") end

			local function go_to_references()
				return vim.lsp.buf.references(
					{ includeDeclaration = false },
					{ on_list = fill_qf_jump_only_if_first }
				)
			end
			action_store.set_action("goto_refs", go_to_references)
			local function goto_refs_action() action_store.exec_action("goto_refs") end

			local rename_symbol = vim.lsp.buf.rename
			local code_actions = vim.lsp.buf.code_action
			local function window_close() vim.api.nvim_buf_delete(0, { force = true }) end

			local function toggle_wrap()
				local prev_wrap = vim.api.nvim_get_option_value("wrap", {})
				local curr_wrap = not prev_wrap
				vim.api.nvim_set_option_value("wrap", curr_wrap, {})
				if curr_wrap then
					vim.api.nvim_set_option_value("textwidth", 0, {})
					vim.api.nvim_set_option_value("colorcolumn", "0", {})
				else
					vim.api.nvim_set_option_value("textwidth", default_text_width, {})
					vim.api.nvim_set_option_value("colorcolumn", tostring(default_text_width), {})
				end
				print(curr_wrap and "wrap" or "nowrap")
			end

			local function run_this_file()
				local cur_file = vim.api.nvim_buf_get_name(0)
				local is_executable = vim.fn.executable(cur_file) == 1
				-- "executable file" case:
				if is_executable then
					nvim_cmd({ "split" })
					nvim_cmd({ "enew" })
					nvim_cmd({ "terminal", cur_file })
					return
				end
				-- "script buffer or file" case:
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local has_shebang_line = vim.startswith(lines[1] or "", "#!")
				if has_shebang_line then
					local temp_file = vim.fn.tempname()
					vim.fn.writefile(lines, temp_file, "")
					vim.uv.fs_chmod(temp_file, 0007)
					local function on_exit() vim.fn.delete(temp_file, "") end
					nvim_cmd({ "split" })
					nvim_cmd({ "enew" })
					vim.fn.jobstart({ temp_file }, { term = true, on_exit = on_exit })
					return
				end
			end
			--
			local function tell_error(msg) vim.notify(msg, vim.log.levels.ERROR) end
			local function run_this_nlua_file()
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
				local chunk, err = loadstring(table.concat(lines, "\n"))
				if err then
					tell_error("Error loading Lua chunk:\n" .. err)
				elseif not chunk then
					tell_error("Unknown error loading Lua chunk!")
				else
					chunk()
				end
			end
			--
			action_store.set_action("run_this_file", run_this_file)
			action_store.set_action("run_this_file", run_this_nlua_file, { filetype = "lua" })
			--
			local function run_this_file_action() action_store.exec_action("run_this_file") end

			local function format() vim.lsp.buf.format({ async = true }) end
			action_store.set_action("format", format)
			local function format_action() action_store.exec_action("format") end

			-- Define actual keybindings:

			-- Apply (C)ode (F)ormatting:
			vim.keymap.set({ "n", "v" }, "<leader>cf", format_action)
			-- Jump to next (D)iagnostic:
			vim.keymap.set("n", "]d", diagno_next)
			-- Jump to previous (D)iagnostic:
			vim.keymap.set("n", "[d", diagno_prev)
			-- Show (D)iagnostic list:
			vim.keymap.set("n", "<leader>qq", diagno_list)
			vim.keymap.set("n", "<leader>rn", rename_symbol)
			vim.keymap.set("n", "<leader>ca", code_actions)
			vim.keymap.set("n", "gd", goto_defs_action)
			vim.keymap.set("n", "gD", goto_typedefs_action)
			-- (G)o to (R)eferences:
			vim.keymap.set("n", "gr", goto_refs_action)
			-- Clear unnecessary default `gr...` keybindings
            -- (overwrite them first):
			vim.keymap.set("n", "gri", "")
			vim.keymap.del("n", "gri")
			vim.keymap.set("n", "gra", "")
			vim.keymap.del("n", "gra")
			vim.keymap.set("n", "grn", "")
			vim.keymap.del("n", "grn")
			vim.keymap.set("n", "grr", "")
			vim.keymap.del("n", "grr")

			-- Prepare a (L)azy-(R)eload command to reload a plugin:
			vim.keymap.set("n", "<leader>lr<space>", ":Lazy<space>reload<space>")
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
			--(R)un this file:
			vim.keymap.set("n", "<leader>rR", run_this_file_action)
			vim.keymap.set("n", "<leader>Rr", run_this_file_action)
			vim.keymap.set("n", "<leader>RR", run_this_file_action)
			--(T)oggle (W)rapping option:
			vim.keymap.set("n", "<leader>tw", toggle_wrap)

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
