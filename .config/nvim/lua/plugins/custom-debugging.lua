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
		"jbyuki/one-small-step-for-vimkind",
		dependencies = "mfussenegger/nvim-dap",
		ft = "lua",
		cmd = "OsvLaunch",
		config = function()
			local dap = require("dap")
			dap.configurations.lua = dap.configurations.lua or {}
			local lua_dap_configs = dap.configurations.lua
			lua_dap_configs[#lua_dap_configs + 1] = {
				type = "osvlua",
				request = "attach",
				name = "Attach to running Neovim instance",
			}
			dap.adapters.osvlua = function(callback, config)
				callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
			end

			vim.api.nvim_create_user_command(
				"OsvLaunch",
				function() require("osv").launch({ port = 8086 }) end,
				{ force = true }
			)
		end,
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
			local ok, mason_registry = pcall(require, "mason-registry")
			if not ok then return false end
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
		dependencies = {
			"igorlfs/nvim-dap-view", -- for semi-advanced UI
		},
		--- @type fun(): LazyKeys[]
		keys = function()
			-- helpers:
			local function dap() return require("dap") end
			local function widgets() return require("dap.ui.widgets") end
			-- complex wrappers:
			local function dap_put_cond_bp()
				---@type string|nil
				local cond = vim.fn.input("Condition: ")
				cond = cond ~= "" and cond or nil
				-- ensure "minimum hits" are a stringified number:
				local hits_num = tonumber(vim.fn.input("Minimum Hits (-): "))
				local hits_str = hits_num and "" .. hits_num
				dap().set_breakpoint(cond, "" .. hits_str)
			end
			--
			local function dap_toggle_frames()
				local view = widgets().sidebar(widgets().frames)
				view.toggle({ width = 40 })
			end
			-- vim commands:
			local dap_open_eval = "<cmd>DapEval<cr>"
			local dap_toggle_view = "<cmd>DapViewToggle<cr>"
			-- simple wrappers:
			local function dap_clear_breakpoints() dap().clear_breakpoints() end
			local function dap_continue() dap().continue() end
			local function dap_step_back() dap().step_back() end
			local function dap_step_into() dap().step_into() end
			local function dap_step_out() dap().step_out() end
			local function dap_step_over() dap().step_over() end
			local function dap_terminate() dap().terminate() end
			local function dap_toggle_bp() dap().toggle_breakpoint() end
			return {
				-- de: open eval
				{ "<leader>de", dap_open_eval, desc = "open DAP REPL in current window" },
				-- df: open frames
				{ "<leader>df", dap_toggle_frames, desc = "DAP: open frames widget" },
				-- dh: step back
				{ "<leader>dh", dap_step_back, desc = "DAP: step back" },
				-- dj: step over
				{ "<leader>dj", dap_step_over, desc = "DAP: step over" },
				-- DJ: run/continue
				{ "<leader>dJ", dap_continue, desc = "DAP: continue (or run)" },
				{ "<leader>DJ", dap_continue, desc = "DAP: continue (or run)" },
				-- dl: step into
				{ "<leader>dl", dap_step_into, desc = "DAP: step into" },
				-- DL: step out
				{ "<leader>dL", dap_step_out, desc = "DAP: step out" },
				{ "<leader>Dl", dap_step_out, desc = "DAP: step out" },
				{ "<leader>DL", dap_step_out, desc = "DAP: step out" },
				-- dp: toggle breakpoint
				{ "<leader>dp", dap_toggle_bp, desc = "DAP: toggle breakpoint" },
				-- DP: toggle conditional breakpoint
				{ "<leader>dP", dap_put_cond_bp, desc = "DAP: put conditional breakpoint" },
				{ "<leader>DP", dap_put_cond_bp, desc = "DAP: put conditional breakpoint" },
				-- dq: clear breakpoints
				{ "<leader>dq", dap_clear_breakpoints, desc = "clear DAP breakpoints" },
				-- DQ: terminate session
				{ "<leader>dQ", dap_terminate, desc = "DAP: terminate session" },
				{ "<leader>Dq", dap_terminate, desc = "DAP: terminate session" },
				{ "<leader>DQ", dap_terminate, desc = "DAP: terminate session" },
				-- dv: toggle DAP view
				{ "<leader>dt", dap_toggle_view, desc = "DAP: toggle DAP view" },
			}
		end,
	},
}
