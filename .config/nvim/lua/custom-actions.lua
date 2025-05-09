---Aggregates custom actions polymorhic depending on the context they're
---executed in.
local M = {}

---@class (exact) custom_actions.Config
---@field default custom_actions.Capabilities
---@field filetype table<custom_actions.FileType, custom_actions.Capabilities>
---@field lsp_enabled { buffer: table<integer, true> }
---
---@alias custom_actions.FileType string
---
---@class (exact) custom_actions.Capabilities
---@field nonlsp? custom_actions.Actions
---@field lsp? custom_actions.Actions
---
---@class (exact) custom_actions.Actions
---@field format? fun()

---@type custom_actions.Config
local actions_cfg = {
	default = {
		nonlsp = {
			format = function() vim.notify("Non-LSP format action unavailable!", vim.log.levels.WARN) end,
		},
		lsp = {
			format = function() return vim.lsp.buf.format({ async = true }) end,
		},
	},
	filetype = {},
	lsp_enabled = { buffer = {} },
}

function M.format()
	local filetype = vim.api.nvim_get_option_value("filetype", {})
	local cur_buf_nr = vim.api.nvim_get_current_buf()
	local ft_capabs = actions_cfg.filetype[filetype] or {}
	-- LSP is not enabled - use filetype-specific or default non-LSP action:
	if not actions_cfg.lsp_enabled.buffer[cur_buf_nr] then
		if type((ft_capabs.nonlsp or {}).format) == "function" then
			return ft_capabs.nonlsp.format()
		else
			return actions_cfg.default.nonlsp.format()
		end
	end
	-- LSP is enabled - use filteype-specific or default LSP action:
	if type(ft_capabs.lsp.format) == "function" then
		return ft_capabs.lsp.format()
	else
		return actions_cfg.default.lsp.format()
	end
end

---Sets format action for the specified filetype.
---@param filetype custom_actions.FileType
---@param format_action fun()
function M.set_lsp_format(filetype, format_action)
	actions_cfg.filetype[filetype] = actions_cfg.filetype[filetype] or {}
	local ft_capabs = actions_cfg.filetype[filetype]
	ft_capabs.lsp = {}
	ft_capabs.lsp.format = format_action
end

---@class custom_actions.format_enable_lsp.Opts
---@field buffer? integer

---Enable language server behavior for a given context.
---@param opts custom_actions.format_enable_lsp.Opts Options specifying context to enable formatting in
function M.enable_lsp(opts)
	opts = opts or {}
	local bufnr = opts.buffer or 0
	actions_cfg.lsp_enabled.buffer[bufnr] = true
end

return M
