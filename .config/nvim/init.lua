-- Leader key has to be set before Lazy:
vim.g.mapleader = " "

-- Enable experimental Lua module loader with bytecode compilation caching:
vim.loader.enable()

-- Bootstrap Lazy plugin manager:
local lazypath = vim.fn.stdpath("state") .. "/lazy/lazy.nvim"
if not vim.uv["fs_stat"](lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
-- Set up Lazy plugins:
require("lazy").setup("plugins")
