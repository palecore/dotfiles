---Configuration for Version Control Systems.

---@type LazySpec[]
return {
	{ "tpope/vim-fugitive" },
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "-" },
				untracked = { text = "?" },
				changedelete = { text = "~" },
			},
			current_line_blame = true,
			current_line_blame_opts = { delay = 2000 },
			preview_config = { border = "shadow" },
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local opts = { buffer = bufnr }

				-- Set up helper functions:
				local function gs_next_change()
					if vim.wo.diff then return "[c" end
					vim.schedule(gs.prev_hunk)
					return "<ignore>"
				end
				local function gs_prev_change()
					if vim.wo.diff then return "]c" end
					vim.schedule(gs.next_hunk)
					return "<ignore>"
				end
				local function gs_reset_hunk_range()
					return gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end
				local function gs_stage_hunk_range()
					return gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end

				-- Set up keybindings:
				vim.keymap.set("n", "[c", gs_next_change, opts)
				vim.keymap.set("n", "]c", gs_prev_change, opts)
				vim.keymap.set("n", "<leader>hi", gs.preview_hunk, opts)
				vim.keymap.set("n", "<leader>ho", gs.reset_hunk, opts)
				vim.keymap.set("v", "<leader>ho", gs_reset_hunk_range, opts)
				vim.keymap.set("n", "<leader>hp", gs.stage_hunk, opts)
				vim.keymap.set("v", "<leader>hp", gs_stage_hunk_range, opts)
				vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, opts)
				vim.keymap.set("n", "<leader>hd", gs.diffthis, opts)
			end,
		},
	},
}
