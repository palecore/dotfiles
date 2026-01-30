local M = {}

local extra_filetypes = {}
function M.add_extra_filetype(ft) extra_filetypes[ft] = true end

function M.filetypes_ext()
	local fzf_lua = require("fzf-lua")
	local item_set = {}
	for _, ft in ipairs(vim.fn.getcompletion("", "filetype")) do
		item_set[ft] = true
	end
	for ft, _ in pairs(extra_filetypes or {}) do
		item_set[ft] = true
	end
	local items = {}
	for ft, _ in pairs(item_set) do
		items[#items + 1] = ft
	end
	table.sort(items)
	fzf_lua.fzf_exec(items, {
		prompt = "> ",
		actions = {
			default = function(selecteds)
				if not selecteds then return end
				if not selecteds[1] then return end
				vim.api.nvim_set_option_value("filetype", selecteds[1], { buf = 0 })
			end,
		},
	})
end

return M
