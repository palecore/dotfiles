---@type LazySpec[]
return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			-- Necessary dependencies:
			"antoinemadec/FixCursorHold.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-neotest/nvim-nio",
			"nvim-treesitter/nvim-treesitter",
			-- Configured adapters:
			"adrigzr/neotest-mocha", -- js: mocha
			"nvim-neotest/neotest-jest", -- js: jest
			"nvim-neotest/neotest-plenary", -- nlua: plenary busted
			"rcasia/neotest-bash", -- bash: bashunit
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-bash"),
					require("neotest-jest")({
						jestCommand = "npm test --",
						jestConfigFile = "custom.jest.config.ts",
						env = { CI = true },
						cwd = vim.fn.getcwd,
					}),
					require("neotest-mocha")({
						command = "npm test --",
						env = { CI = true },
						cwd = vim.fn.getcwd,
					}),
					require("neotest-plenary"),
				},
				icons = {
					child_indent = "|",
					child_prefix = "+",
					collapsed = "-",
					expanded = "+",
					failed = "X",
					final_child_indent = " ",
					final_child_prefix = "+",
					non_collapsible = " ",
					notify = "!",
					passed = "V",
					running = "~",
					skipped = ".",
					unknown = "?",
					watching = "@",
				},
				summary = {
					mappings = {
						watch = "W",
					},
				},
			})
		end,
		keys = {
			{
				"<leader>us",
				function() require("neotest").summary.open() end,
				id = "neotest_summary_open",
			},
			{
				"<leader>ur",
				function() require("neotest").run.run() end,
				id = "neotest_run_this",
			},
			{
				"<leader>uR",
				function() require("neotest").run.run(vim.fn.expand("%")) end,
				desc = "run all tests in the current file",
				id = "neotest_run_file1",
			},
			{
				"<leader>UR",
				function() require("neotest").run.run(vim.fn.expand("%")) end,
				desc = "run all tests in the current file",
				id = "neotest_run_file2",
			},
			{
				"<leader>ud",
				function() require("neotest").run.run({ suite = false, strategy = "dap" }) end,
				desc = "debug the nearest test",
				id = "neotest_debug_this",
			},
			{
				"<leader>uo",
				function() require("neotest").output.open({ enter = true }) end,
				desc = "show output of the nearest test",
				id = "neotest_show_output",
			},
			-- TODO <leader>uq - clean up annotations
		},
	},
}
