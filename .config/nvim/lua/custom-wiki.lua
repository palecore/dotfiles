---Helper module to set up configuration for vimwiki.
local M = {}

---@return (string|LazyKeys)[]
function M.vimwiki_keys()
	---@type (string|LazyKeys)[]
	return {
		"<leader>ww",
		"<leader>w<leader>w",
		{ "<leader>w<C-H>", "<cmd>VimwikiDiaryPrevDay<cr>", id = "vimwiki_prev_day" },
		{ "<leader>w<C-L>", "<cmd>VimwikiDiaryNextDay<cr>", id = "vimwiki_next_day" },
	}
end

function M.kiwi_keys()
	---@type (string|LazyKeys)[]
	return {
		"<leader>ww",
		"<leader>w<leader>w",
		{ "<leader>w<C-H>", "<cmd>VimwikiDiaryPrevDay<cr>", id = "vimwiki_prev_day" },
		{ "<leader>w<C-L>", "<cmd>VimwikiDiaryNextDay<cr>", id = "vimwiki_next_day" },
	}
end

---@class custom_wiki.WikiDir
---@field path string
---@field diary_rel_path? string

---@param wiki_dirs custom_wiki.WikiDir[]
local function vimwiki_init(wiki_dirs)
	vim.g.vimwiki_folding = "" -- "expr" is slow
	vim.g.vimwiki_hl_cb_checked = 2
	vim.g.vimwiki_hl_headers = 1

	vim.g.vimwiki_listsyms = " x"
	vim.g.vimwiki_markdown_link_ext = 1
	local vimwiki_list = {}
	for idx, wiki_dir in ipairs(wiki_dirs) do
		vimwiki_list[idx] = {
			path = wiki_dir.path,
			diary_rel_path = wiki_dir.diary_rel_path,
			syntax = "markdown",
			ext = ".md",
			links_space_char = "-",
		}
	end
	vim.g.vimwiki_list = vimwiki_list
end

---@param wiki_dirs custom_wiki.WikiDir[]
---@return fun(self: LazyPlugin)
function M.vimwiki_init_fn(wiki_dirs)
	return function() vimwiki_init(wiki_dirs) end
end

---@param opts { wiki_dirs: custom_wiki.WikiDir[] }
---@return LazySpec
function M.vimwiki_lazy_spec(opts)
	opts = opts or {}
	local wiki_dirs = opts.wiki_dirs or {}
	---@type LazySpec
	return {
		"vimwiki/vimwiki",
		keys = M.vimwiki_keys(),
		init = M.vimwiki_init_fn(wiki_dirs)
	}
end

return M
