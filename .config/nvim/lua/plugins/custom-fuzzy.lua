---@type LazySpec
return {
	"ibhagwan/fzf-lua",
	cmd = "FzfLua",
	config = function()
		local fzf_lua = require("fzf-lua")
		fzf_lua.setup({
			"max-perf",
			winopts = {
				width = 0.9,
				height = 0.9,
				preview = {
					default = "bat",
					horizontal = "right:50%",
					border = "noborder",
				},
				border = false,
			},
			fzf_opts = { ["--layout"] = "default" },
			keymap = {
				fzf = {
					["ctrl-f"] = "forward-char",
					["ctrl-b"] = "backward-char",
				},
			},
		})
		fzf_lua.register_ui_select()
	end,
	---@type fun(): LazyKeys[]
	keys = function()
		local fzf_lua = require("custom-helpers").lazy_require("fzf-lua")

		local fzf_lua_grep_git_files = function()
			return fzf_lua.grep_project({
				fzf_opts = { ["--ansi"] = true },
				cmd = "git grep --line-number --column --color=always",
				cwd = vim.fn.systemlist({
					"git",
					"rev-parse",
					"--show-toplevel",
				})[1],
			})
		end

		local function fzf_lua_custom_git_branches()
			local function tell_error(msg)
				vim.notify(msg, vim.log.levels.ERROR)
				pcall(function() error(msg) end)
			end
			local function tell_info(msg) vim.notify(msg) end
			local function system_or_notify(_cmd)
				local output = ""
				local proc = vim
					.system(_cmd, {
						stdout = function(err, data)
							if not err and data then output = output .. data end
						end,
						stderr = function(err, data)
							if not err and data then output = output .. data end
						end,
					})
					:wait()
				if proc.code ~= 0 then
					tell_error(_cmd[1] .. ": " .. output)
					return false
				end
				return true
			end
			return fzf_lua.git_branches({
				headers = {}, -- because we set a custom header below
				fzf_opts = {
					["--header"] = ":: " .. table.concat({
						"<alt-x> to delete",
						"<alt-X> to force-delete",
					}, "|"),
				},
				actions = {
					["default"] = function(selected, options)
						if #selected == 0 then
							local new_branch = options.__call_opts.query
							if system_or_notify({ "git", "switch", "-c", new_branch }) then
								tell_info("Created branch " .. new_branch)
							end
							return
						end

						local branch = selected[1]:sub(3)
						-- if it's a nonexistent remote branch, cut the remote prefix:
						if branch:match("^remotes/origin/..*") then branch = branch:sub(16) end
						if system_or_notify({ "git", "switch", "--", branch }) then
							tell_info("Checked out to branch " .. branch)
						end
					end,
					["ctrl-a"] = false, -- by default it seems to create a branch
					["alt-x"] = {
						fn = function(selected)
							if not selected[1] then return end
							local branch = string.sub(selected[1], 3)
							if system_or_notify({ "git", "branch", "-d", branch }) then
								tell_info("Deleted branch " .. branch)
							end
						end,
						reload = true,
					},
					["alt-X"] = {
						fn = function(selected)
							if not selected[1] then return end
							local branch = string.sub(selected[1], 3)
							local utils = require("fzf-lua.utils")
							local confirm = utils.input("Force-delete branch " .. branch .. "? [y/N] ")
							if confirm ~= "y" then return end
							if system_or_notify({ "git", "branch", "-D", branch }) then
								tell_info("Force-deleted branch " .. branch)
							end
						end,
						reload = true,
					},
				},
			})
		end

		return {
			{ "<leader>f<space>", id = "fzf_lua_resume", fzf_lua.resume },
			{ "<leader>ft", id = "fzf_lua_tags", fzf_lua.tags },
			{ "<leader>fh", id = "fzf_lua_oldfiles", fzf_lua.oldfiles },
			{ "<leader>fl", id = "fzf_lua_blines", fzf_lua.blines },
			{ "<leader>f/", id = "fzf_lua_help_tags", fzf_lua.help_tags },
			{ "<leader>ff", id = "fzf_lua_files", fzf_lua.files },
			{ "<leader>fF", id = "fzf_lua_filetypes1", fzf_lua.filetypes },
			{ "<leader>FF", id = "fzf_lua_filetypes2", fzf_lua.filetypes },
			{ "<leader>fb", id = "fzf_lua_buffers", fzf_lua.buffers },
			{ "<leader>fc", id = "fzf_lua_commands", fzf_lua.commands },
			{ "<leader>fa", id = "fzf_lua_grep_project", fzf_lua.grep_project },
			{ "<leader>fA", id = "fzf_lua_grep_git_files", fzf_lua_grep_git_files },
			{ "<leader>FA", id = "fzf_lua_grep_git_files", fzf_lua_grep_git_files },
			{ "<leader>fg", id = "fzf_lua_git_status", fzf_lua.git_status },
			{ "<leader>fG", id = "fzf_lua_git_files", fzf_lua.git_files },
			{ "<leader>FG", id = "fzf_lua_git_files", fzf_lua.git_files },
			{
				"<leader>fs",
				id = "fzf_lua_lsp_document_symbols",
				fzf_lua.lsp_document_symbols,
			},
			{ "<leader>fS", id = "fzf_lua_git_stash", fzf_lua.git_stash },
			{ id = "fzf_lua_git_stash", "<leader>FS", fzf_lua.git_stash },
			{
				"<leader>fB",
				id = "fzf_lua_custom_git_branches",
				fzf_lua_custom_git_branches,
			},
			{
				"<leader>FB",
				id = "fzf_lua_custom_git_branches",
				fzf_lua_custom_git_branches,
			},
			{ "<leader>fC", id = "fzf_lua_git_commits", fzf_lua.git_commits },
			{ "<leader>FC", id = "fzf_lua_git_commits", fzf_lua.git_commits },
			{ "<leader>fq", id = "fzf_lua_quickfix", fzf_lua.quickfix },
			{ "<leader>fQ", id = "fzf_lua_quickfix_stack", fzf_lua.quickfix_stack },
			{ "<leader>FQ", id = "fzf_lua_quickfix_stack", fzf_lua.quickfix_stack },
			{
				"<leader>fL",
				id = "fzf_lua_lsp_live_workspace_symbols",
				fzf_lua.lsp_live_workspace_symbols,
			},
			{
				"<leader>FL",
				id = "fzf_lua_lsp_live_workspace_symbols",
				fzf_lua.lsp_live_workspace_symbols,
			},
		}
	end,
}
