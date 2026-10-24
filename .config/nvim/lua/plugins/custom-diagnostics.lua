local function trouble_close()
	require("trouble").close({ mode = "diagnostics" })
	require("trouble").close({ mode = "symbols" })
end

local function trouble_toggle_diagno_buf()
	require("trouble").toggle({
		filter = { buf = 0 },
		mode = "diagnostics",
	})
end

local function trouble_toggle_diagno_all()
	require("trouble").toggle({
		mode = "diagnostics",
	})
end

local function trouble_toggle_symbols_buf()
	require("trouble").toggle({
		filter = { buf = 0 },
		mode = "symbols",
		focus = true,
	})
end

local function trouble_toggle_symbols_all()
	require("trouble").toggle({
		mode = "symbols",
		focus = true,
	})
end

local function trouble_open_refs() require("trouble").open({ mode = "lsp_references" }) end

local function trouble_open_defs()
	require("trouble").open({
		mode = "lsp_definitions",
	})
end

---@type LazySpec
return {
	"folke/trouble.nvim",
	-- This needs to run after custom-general, to properly overwrite custom actions:
	-- (NOTE: as a workaround, currently general configs are kept under lualine)
	dependencies = "nvim-lualine/lualine.nvim",
	---@type trouble.Config
	opts = {
		auto_jump = true,
		open_no_results = false,
		warn_no_results = true,
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
		{
			"<leader>di",
			trouble_toggle_diagno_buf,
			id = "trouble_toggle_diagno_buf",
			desc = "Toggle Buffer Issues",
		},
		{
			"<leader>dI",
			trouble_toggle_diagno_all,
			id = "trouble_toggle_diagno_all1",
			desc = "Toggle Global Issues",
		},
		{
			"<leader>Di",
			trouble_toggle_diagno_all,
			id = "trouble_toggle_diagno_all2",
			desc = "Toggle Global Issues",
		},
		{
			"<leader>DI",
			trouble_toggle_diagno_all,
			id = "trouble_toggle_diagno_all3",
			desc = "Toggle Global Issues",
		},
		{
			"<leader>do",
			trouble_toggle_symbols_buf,
			id = "trouble_toggle_symbols_buf",
			desc = "Toggle Buffer Symbols",
		},
		{
			"<leader>dO",
			trouble_toggle_symbols_all,
			id = "trouble_toggle_symbols_all1",
			desc = "Toggle Global Symbols",
		},
		{
			"<leader>Do",
			trouble_toggle_symbols_all,
			id = "trouble_toggle_symbols_all2",
			desc = "Toggle Global Symbols",
		},
		{
			"<leader>DO",
			trouble_toggle_symbols_all,
			id = "trouble_toggle_symbols_all3",
			desc = "Toggle Global Symbols",
		},
		{ "<leader>dq", trouble_close, id = "trouble_close", desc = "Close Trouble View" },
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
