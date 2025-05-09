---Salesforce-development-specific configuration
---@type LazySpec
return {
	name = "custom-sf",
	dir = "/dev/null",
	config = function()
		-- Various Salesforce metadata components have non-conventional extensions:
		vim.filetype.add({
			extension = {
				design = "xml",
				component = "xml",
				trigger = "apex",
			},
		})
	end,
}
