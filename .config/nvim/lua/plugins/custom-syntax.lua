---Custom syntax-processing plugins.

---@type LazySpec[]
return {
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = "nvim-treesitter/nvim-treesitter",
		opts = {
			max_lines = 3,
			min_window_height = 16,
			on_attach = function()
				vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
			end,
		},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false, -- This plugin explicitly mentions it does not support lazy-loading.
		branch = "main",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({})
			-- explicitly specify extra filetypes that should expect & use treesitter highlighting
			local ts_hl_extra_filetypes = {
			}
			vim.api.nvim_create_autocmd("FileType", {
				pattern = ts_hl_extra_filetypes,
				callback = function() vim.treesitter.start() end,
			})
			-- Highlight vimwiki files as markdown:
			vim.treesitter.language.register("markdown", { "vimwiki" })
			-- Explicitly highlight variables as identifiers:
			require("custom-helpers").on_lazy_done(
				function() vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" }) end
			)
		end,
	},
}
