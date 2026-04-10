local M = {}

function M.buf_toggle()
	-- explicitly enable Copilot in case it's the first time:
	vim.api.nvim_cmd({ cmd = "Copilot", mods = { silent = true } }, {})
	vim.b.copilot_enabled = not vim.b.copilot_enabled
end

function M.global_disable()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		pcall(vim.api.nvim_buf_del_var, buf, "copilot_enabled")
	end
end

function M.is_buf_enabled() return not not vim.b.copilot_enabled end

---@deprecated
function M.buf_status() return vim.b.copilot_enabled and "GHAI" or "" end

function M.buf_status_def()
	return {
		"b:copilot_enabled",
		fmt = function(enabled) return enabled == "true" and "A" or "" end,
		color = { fg = "black", bg = "orange" },
	}
end

return M
