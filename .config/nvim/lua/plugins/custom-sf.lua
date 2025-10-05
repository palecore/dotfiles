---Salesforce-development-specific configuration

-- Various Salesforce metadata components have non-conventional extensions:
vim.filetype.add({
	extension = {
		design = "xml",
		component = "xml",
		trigger = "apex",
	},
})

---@type LazySpec[]
return {}
