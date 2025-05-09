---@type LazySpec[]
return {
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
	},
	{
		name = "custom-debugger-lua",
		dir = "/dev/null",
		dependencies = {
			-- To detect location of local-lua debugger:
			"mason-org/mason.nvim",
			-- To supplement nvim-dap's configuration:
			"mfussenegger/nvim-dap",
		},
		ft = "lua",
		-- This can work only if local-lua-debugger-vscode is installed.
		-- For now, only Mason installation is accepted.
		cond = function()
			local mason_registry = require("mason-registry")
			local debugger_name = "local-lua-debugger-vscode"
			return mason_registry.has_package(debugger_name)
		end,
		config = function()
			local dap = require("dap")
			dap.configurations.lua = {
				{
					name = "Current file (local-lua-dbg, lua)",
					type = "local-lua",
					request = "launch",
					cwd = "${workspaceFolder}",
					program = {
						lua = "lua5.1",
						file = "${file}",
					},
					args = {},
				},
				{
					name = "Current file (local-lua-dbg, nlua)",
					type = "local-lua",
					request = "launch",
					cwd = "${workspaceFolder}",
					program = {
						lua = "nlua",
						file = "${file}",
					},
					args = {},
				},
			}

			local debugger_mason_install_dir = vim.fn.stdpath("data")
				.. "/mason/packages/local-lua-debugger-vscode/extension"
			local debugger_entry_path = debugger_mason_install_dir .. "/extension/debugAdapter.js"
			local debugger_lua_module_path = debugger_mason_install_dir

			dap.adapters["local-lua"] = {
				type = "executable",
				command = "node",
				args = { debugger_entry_path },
				enrich_config = function(config, on_config)
					if not config["extensionPath"] then
						local c = vim.deepcopy(config)
						c.extensionPath = debugger_lua_module_path
						on_config(c)
					else
						on_config(config)
					end
				end,
			}
			dap.adapters.nlua = dap.adapters["local-lua"]
		end,
	},
	{
		"mfussenegger/nvim-dap",
		--- @type fun(): LazyKeys[]
		keys = function()
			local lazy_require = require("custom-helpers").lazy_require
			--
			local dap = lazy_require("dap")
			local dap_toggle_bp = dap.toggle_breakpoint
			local function dap_put_cond_bp()
				---@type string|nil
				local cond = vim.fn.input("Condition: ")
				cond = cond ~= "" and cond or nil
				-- ensure "minimum hits" are a stringified number:
				local hits_num = tonumber(vim.fn.input("Minimum Hits (-): "))
				local hits_str = hits_num and "" .. hits_num
				dap.set_breakpoint(cond, "" .. hits_str)
			end
			local function dap_open_repl_here()
				local buf, win = require("dap").repl.open()
				vim.api.nvim_set_current_buf(buf)
				vim.api.nvim_win_close(win, true)
			end
			return {
				{ "<leader>dp", dap_toggle_bp, desc = "DAP: toggle breakpoint" },
				{ "<leader>dj", dap.step_over, desc = "DAP: step over" },
				{ "<leader>dJ", dap.continue, desc = "DAP: continue (or run)" },
				{ "<leader>DJ", dap.continue, desc = "DAP: continue (or run)" },
				{ "<leader>dl", dap.step_into, desc = "DAP: step into" },
				{ "<leader>dL", dap.list_breakpoints, desc = "list DAP breakpoints" },
				{ "<leader>DL", dap.list_breakpoints, desc = "list DAP breakpoints" },
				{ "<leader>dh", dap.step_back, desc = "DAP: step back" },
				{ "<leader>dq", dap.clear_breakpoints, desc = "clear DAP breakpoints" },
				{ "<leader>dP", dap_put_cond_bp, desc = "DAP: put conditional breakpoint" },
				{ "<leader>DP", dap_put_cond_bp, desc = "DAP: put conditional breakpoint" },
				{ "<leader>de", dap_open_repl_here, desc = "open DAP REPL in current window" },
			}
		end,
	},
}
