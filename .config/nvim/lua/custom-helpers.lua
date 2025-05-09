---Custom helper utilities for my neovim configuration.
---
---NOTE: global variable is used to work well with lazydev.nvim.
local M = {}

---Execute one vim command and return its outputs.
---@param cmd_or_args string|string[]
---@param opts? table
---@return string? cmd_output
function M.nvim_cmd(cmd_or_args, opts)
	local cmdname
	local args
	if type(cmd_or_args) == "string" then
		cmdname = cmd_or_args
		args = {}
	elseif type(cmd_or_args) == "table" then
		cmdname = table.remove(cmd_or_args, 1)
		args = cmd_or_args
	else
		error("Unexpected type of cmd_or_args: " .. type(cmd_or_args))
		return nil
	end
	--
	opts = opts or {}
	if opts.bang == nil then opts.bang = false end
	--
	return vim.api.nvim_cmd({ cmd = cmdname, args = args, bang = opts.bang }, { output = true })
end

---Sets up a callback to be executed after all lazy plugins are set up.
---Nvim autocmd is used; it runs once and clears itself.
---@param fn fun()
function M.on_lazy_done(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "LazyDone",
		callback = function()
			fn()
			return true
		end,
	})
end

---Creates a closure that'll invoke `fn` with provided varargs.
---@generic Input
---@generic Output
---@param fn fun(...: Input): Output
---@param ... Input
---@return fun(): Output
function M.lazy_fn(fn, ...)
	local unpack = table.unpack or unpack
	local args = { ... }
	return function() return fn(unpack(args)) end
end

---Creates a lazy module which won't be imported until any field of it will be
---invoked (as a function).
---@return table
function M.lazy_require(modname)
	return setmetatable({}, {
		__index = function(_, k)
			return function(...) require(modname)[k](...) end
		end,
	})
end

return M
