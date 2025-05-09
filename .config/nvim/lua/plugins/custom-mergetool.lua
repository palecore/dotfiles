---@type LazySpec
return {
	"samoshkin/vim-mergetool",
	keys = {
		{ "<leader>tm", "<plug>(MergetoolToggle)", id = "mergetool_toggle" },
	},
	init = function()
		vim.g.mergetool_layout = "mr"
		vim.g.mergetool_prefer_revision = "local"
		vim.g.MergetoolSetLayoutCallback = function(split)
			-- make every buffer modifiable for conflict resolution convenience:
			local bufnr = assert(split.bufnr)
			vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
			vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
		end
	end,
}
