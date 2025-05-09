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
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				auto_install = false,
				ignore_install = {},
				modules = {},
				sync_install = false,
				ensure_installed = {
					"bash",
					"jq",
					"lua",
					"markdown",
					"markdown_inline",
					"yaml",
					"vimdoc", -- Without this, huge "Impossible Query" errors on vim docs.
				},
				highlight = { enable = true },
				indent = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						node_incremental = "<c-n>",
						node_decremental = "<c-p>",
					},
				},
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
