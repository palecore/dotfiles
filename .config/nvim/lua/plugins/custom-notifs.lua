---@type LazySpec[]
return {
	{
		"j-hui/fidget.nvim",
		opts = {
			progress = {
				suppress_on_insert = true,
				ignore_done_already = true,
				display = {
					done_ttl = 2,
					done_icon = "v",
					progress_icon = { "line" },
				},
			},
			notification = {
				filter = vim.log.levels.INFO,
			},
		},
	},
	{
		"rcarriga/nvim-notify",
		config = function()
			local ntf = require("notify")
			ntf.setup({
				stages = "static",
				top_down = true,
				render = "minimal",
				icons = {
					DEBUG = "D",
					ERROR = "E",
					INFO = "I",
					TRACE = "T",
					WARN = "W",
				},
			})
			vim.notify = ntf
		end,
	},
}
