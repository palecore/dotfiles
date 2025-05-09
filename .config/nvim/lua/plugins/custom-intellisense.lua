---@type LazySpec[]
return {
	{
		"nvimtools/none-ls.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.code_actions.refactoring,
					null_ls.builtins.diagnostics.actionlint,
					null_ls.builtins.formatting.shfmt.with({
						extra_args = {
							"--binary-next-line",
							"--case-indent",
							"--func-next-line",
							"--space-redirects",
						},
					}),
					null_ls.builtins.formatting.prettierd.with({
						extra_filetypes = { "apex" },
						-- HTML breaks LWC templates (e.g. bracket expressions):
						disabled_filetypes = { "html" },
						extra_args = { "--plugin=prettier-plugin-apex" },
					}),
					null_ls.builtins.formatting.stylua,
				},
			})
		end,
	},
	{
		--- Neovim configuration development
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			---@type lazydev.Library.spec[]
			library = {
				"blink.cmp",
				"lazy.nvim",
				"lazydev.nvim",
				"neotest",
				"none-ls.nvim",
				"plenary.nvim",
				"vim.lsp",
				"vim.uv",
			},
		},
	},
	{ "mason-org/mason.nvim", optional = true, opts = {} },
	{
		-- General intellisense configuration
		name = "custom-intellisense",
		dir = "/dev/null", -- Fake plugin - the whole logic is contained here.
		dependencies = {
			-- To leverage custom, context-specific actions
			"custom-actions",
			-- To locally set up various language servers, linters etc.:
			"mason-org/mason.nvim",
			-- For community-maintained language server configs:
			"neovim/nvim-lspconfig",
			-- For extending LSP capabilities with autocompletion-supported ones:
			"saghen/blink.cmp",
		},
		config = function()
			-- Adjust all language server configurations with keybindings and
			-- completion-supported capabilities:
			local capabs = require("blink.cmp").get_lsp_capabilities()
			vim.lsp.config("*", {
				capabilities = capabs,
				on_attach = function(_, bufnr) CustomActions.enable_lsp({ buffer = bufnr }) end,
			})

			-- Adjust some language server configurations according to custom needs:

			---@type vim.lsp.ClientConfig
			vim.lsp.config.apex_ls = {
				cmd = { "/usr/bin/env", "apex-jorje-lsp" },
				root_markers = "sfdx-project.json",
				filetypes = { "apex" },
				settings = { apex_enable_semantic_errors = true },
			}

			vim.lsp.config("awk_ls", {
				single_file_support = true,
				handlers = {
					["workspace/workspaceFolders"] = function()
						return {
							{
								uri = "file://" .. vim.fn.getcwd(),
								name = "current_dir",
							},
						}
					end,
				},
			})

			vim.lsp.config("fregels", {
				cmd = { "frege-lsp-server" },
				filetypes = { "frege" },
				root_markers = "pom.xml",
			})

			--Enable (broadcasting) snippet capability for completion
			local jsonls_capabs = require("blink.cmp").get_lsp_capabilities()
			jsonls_capabs.textDocument.completion.completionItem.snippetSupport = true
			vim.lsp.config("jsonls", {
				capabilities = jsonls_capabs,
				settings = {
					json = {
						format = { enable = true },
						schemas = {
							{
								fileMatch = { "sfdx-project.json" },
								url = "https://raw.githubusercontent.com/forcedotcom/schemas/main/sfdx-project.schema.json",
							},
							{
								fileMatch = { "project-scratch-def.json" },
								url = "https://raw.githubusercontent.com/forcedotcom/schemas/main/project-scratch-def.schema.json",
							},
						},
					},
				},
			})

			-- For lua files, format explicitly with stylua (through null-ls):
			CustomActions.set_lsp_format(
				"lua",
				function() return vim.lsp.buf.format({ async = true, name = "null-ls" }) end
			)

			vim.lsp.config("teal_ls", { single_file_support = true })

			vim.lsp.config("yamlls", {
				settings = {
					yaml = {
						format = {
							bracketSpacing = true,
						},
						keyOrdering = false,
						schemas = {
							["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
							["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.9.9-standalone-strict/pod.json"] = "*pod.y*ml",
							["https://kubernetesjsonschema.dev/v1.14.0/deployment-apps-v1.json"] = {
								"*deployment.y*ml",
								"*deploy.y*ml",
							},
							["https://kubernetesjsonschema.dev/v1.10.3-standalone/service-v1.json"] = {
								"*service.y*ml",
								"*svc.y*ml",
							},
						},
					},
				},
			})

			-- Enable used language server configurations:
			vim.lsp.enable({
				"apex_ls",
				"awk_ls",
				"bashls",
				"cssls",
				"denols",
				"dhall_lsp_server",
				"elmls",
				"gradle_ls",
				"hls",
				"html",
				"jdtls",
				"jsonls",
				"kotlin_language_server",
				"lemminx",
				"lua_ls",
				"purescriptls",
				"pyright",
				"ruff",
				"rust_analyzer",
				"teal_ls",
				"vimls",
				"yamlls",
			})
		end,
	},
}
