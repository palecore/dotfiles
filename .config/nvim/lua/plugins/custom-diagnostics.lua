local function trouble_open_mixed()
	require("trouble.api").open({
		mode = "diagnostics",
		sections = { "diagnostics", "symbols" },
	})
end

local function trouble_open_refs() require("trouble.api").open({ mode = "lsp_references" }) end

local function trouble_open_defs()
	require("trouble.api").open({
		mode = "lsp_definitions",
		sections = {
			"lsp_definitions",
			"lsp_implementations",
			"lsp_declarations",
			"lsp_type_definitions",
		},
	})
end

---@type LazySpec
return {
	"folke/trouble.nvim",
	-- This needs to run after custom-general, to properly overwrite custom actions:
	dependencies = "custom-general",
	---@type trouble.Config
	opts = {
		auto_jump = true,
		open_no_results = true,
		focus = true,
		multiline = false,
		---@type trouble.Window.opts
		win = {
			type = "split",
			position = "right",
			padding = { top = 0, left = 0 },
			---@diagnostic disable-next-line: missing-fields
			wo = {
				showbreak = "    ",
				colorcolumn = "",
			},
			size = {
				height = 8,
				width = 64,
			},
		},
		keys = {
			["<c-w>c"] = "close",
		},
		icons = {
			indent = {
				top = "| ",
				middle = "|-",
				last = "+-",
				fold_open = "v-",
				fold_closed = "^-",
			},
			folder_closed = "^",
			folder_open = "v",
			kinds = {
				Array = "Ar ",
				Boolean = "Bl ",
				Class = "C  ",
				Constant = "Ct ",
				Constructor = "Cr ",
				Enum = "E  ",
				EnumMember = "EM ",
				Event = "Ev ",
				Field = "Fd ",
				File = "Fe ",
				Function = "F  ",
				Interface = "I  ",
				Key = "K  ",
				Method = "Mt ",
				Module = "Md ",
				Namespace = "Ns ",
				Null = "Nl ",
				Number = "Nu ",
				Object = "Ob ",
				Operator = "Op ",
				Package = "Pk ",
				Property = "Pr ",
				String = "Sg ",
				Struct = "S ",
				TypeParameter = "TP ",
				Variable = "V  ",
			},
		},
	},
	cmd = "Trouble",
	event = "LspAttach",
	keys = {
		{ "<leader>di", trouble_open_mixed, id = "trouble_open_mixed", desc = "Open Trouble View" },
	},
	config = function(_, opts)
		require("trouble").setup(opts)
		require("custom-action-store").set_action("goto_refs", trouble_open_refs)
		require("custom-action-store").set_action("goto_defs", trouble_open_defs)
		require("custom-action-store").set_action("goto_typedefs", trouble_open_defs)
		require("custom-helpers").on_lazy_done(function()
			vim.api.nvim_set_hl(0, "TroubleIndent", { link = "TroubleNormal" })
			vim.api.nvim_set_hl(0, "TroubleIndentWs", { link = "TroubleNormal" })
		end)
	end,
}
