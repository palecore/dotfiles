---Aggregates custom actions polymorhic depending on the context they're
---executed in.
local M = {}

local action_store = {
	---@type table<integer, table<string, function>>
	buffer = {},
	---@type table<integer, table<string, function>>
	window = {},
	---@type table<integer, table<string, function>>
	tabpage = {},
	---@type table<string, table<string, function>>
	filetype = {},
	---@type table<string, function>
	global = {},
}

---Executes the action
---@param action_name custom_action_store.ActionName
---@param payload? table for future use
---@return nil result for future use
function M.exec_action(action_name, payload)
	local bufnr = vim.api.nvim_get_current_buf()
	local buf_action = (action_store.buffer[bufnr] or {})[action_name]
	if type(buf_action) == "function" then return buf_action(payload) end
	--
	local winnr = vim.api.nvim_get_current_win()
	local win_action = (action_store.window[winnr] or {})[action_name]
	if type(win_action) == "function" then return win_action(payload) end
	--
	local tab = vim.api.nvim_get_current_tabpage()
	local tab_action = (action_store.tabpage[tab] or {})[action_name]
	if type(tab_action) == "function" then return tab_action(payload) end
	--
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	local ft_action = (action_store.filetype[ft] or {})[action_name]
	if type(ft_action) == "function" then return ft_action(payload) end
	--
	local global_action = action_store.global[action_name]
	if type(global_action) == "function" then return global_action(payload) end
	--
	vim.notify("Unset action '" .. action_name .. "'!", vim.log.levels.ERROR)
	return nil
end

---@alias custom_action_store.ActionName
---| string

---@alias custom_action_store.Scope
---| { buffer: integer }
---| { window: integer }
---| { tabpage: integer }
---| { filetype: string }
---| nil

---@alias custom_action_store.ActionFn
---| fun()

---@param action_name custom_action_store.ActionName
---@param action_fn custom_action_store.ActionFn
---@param scope custom_action_store.Scope
function M.set_action(action_name, action_fn, scope)
	-- TODO set up autocmds to clean these up on buf/win/tab destruction
	-- TODO: provide fallback function if overwriting
	if scope and scope.buffer then
		local buf_actions = action_store.buffer[scope.buffer] or {}
		buf_actions[action_name] = action_fn
		action_store.buffer[scope.buffer] = buf_actions
	elseif scope and scope.window then
		local win_actions = action_store.window[scope.window] or {}
		win_actions[action_name] = action_fn
		action_store.window[scope.window] = win_actions
	elseif scope and scope.tabpage then
		local tab_actions = action_store.tabpage[scope.tabpage] or {}
		tab_actions[action_name] = action_fn
		action_store.tabpage[scope.tabpage] = tab_actions
	elseif scope and scope.filetype then
		local ft_actions = action_store.filetype[scope.filetype] or {}
		ft_actions[action_name] = action_fn
		action_store.filetype[scope.filetype] = ft_actions
	else
		action_store.global[action_name] = action_fn
	end
end

return M
