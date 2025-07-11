---@type LazySpec
return {
	"stevearc/oil.nvim",
	lazy = false, -- has to be always loaded replace netrw in opening dirs
	cmd = "Oil",
	keys = {
		{ "-", function() require("oil").open() end, id = "oil_open_parent_dir" },
	},
	opts = {
		default_file_explorer = true,
		skip_confirm_for_simple_edits = true,
		columns = { "permissions", "size", "mtime" },
		view_options = { show_hidden = true },
	},
}
