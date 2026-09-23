local helpers = require("codecompanion.interactions.chat.tools.builtin.helpers")
local markdown = require("codecompanion.utils.markdown")

local fmt = string.format

---Create a command-line tool from a specification table.
---
---This factory function returns a complete CodeCompanion tool table that
---executes shell commands. Users provide a minimal spec and get a fully
---functional tool with schema, approval prompts, and output handling.
---
---@param spec { name: string, description: string, schema: { properties: table, required: table, additionalProperties?: boolean }, build_cmd: fun(args: table): string, system_prompt?: string|fun(schema: table): string, handlers?: table, output?: table, gates?: table, stderr?: boolean }
---@return CodeCompanion.Tools.Tool
local function cmd_tool(spec)
	-- Build the full schema envelope from the user's property spec
	local schema = {
		type = "function",
		["function"] = {
			name = spec.name,
			description = spec.description,
			parameters = {
				type = "object",
				properties = spec.schema.properties,
				required = spec.schema.required,
				additionalProperties = spec.schema.additionalProperties or false,
			},
			strict = true,
		},
	}

	-- Default handlers
	local default_handlers = {
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools }
		setup = function(self, meta)
			meta = meta
			local cmd_string = spec.build_cmd(self.args)
			local cmd = { cmd = vim.split(cmd_string, " ") }
			table.insert(self.cmds, cmd)
		end,
	}

	-- Default output handlers
	local default_output = {
		---Returns the command that will be executed
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools }
		---@return string
		cmd_string = function(self, meta) return spec.build_cmd(self.args) end,

		---@param self CodeCompanion.Tools.Tool
		---@param stderr table The error output from the command
		---@param meta { tools: CodeCompanion.Tools, cmd: table }
		error = function(self, stderr, meta)
			if stderr and spec.stderr ~= false then
				local chat = meta.tools.chat
				local cmd_string = spec.build_cmd(self.args)
				local errors = vim.iter(stderr):flatten():join("\n")

				local content = markdown.form_codeblock(errors, { ft = "txt" })

				local llm_output =
					fmt("There was an error running the `%s` command:\n%s", cmd_string, content)
				local user_output = fmt("`%s` error\n%s", cmd_string, content)

				chat:add_tool_output(self, llm_output, user_output)
			end
		end,

		---Prompt the user to approve the execution of the command
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools }
		---@return string
		prompt = function(self, meta) return fmt("Run the command `%s`?", spec.build_cmd(self.args)) end,

		---Rejection message back to the LLM
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools, cmd: string, opts: table }
		---@return nil
		rejected = function(self, meta)
			local content = fmt("The user rejected the execution of the `%s` tool", spec.name)
			meta = vim.tbl_extend("force", { message = content }, meta or {})
			helpers.rejected(self, meta)
		end,

		---@param self CodeCompanion.Tools.Tool
		---@param stdout table|nil The output from the tool
		---@param meta { tools: table, cmd: table }
		---@return nil
		success = function(self, stdout, meta)
			local chat = meta.tools.chat
			if stdout then
				local output = vim.iter(stdout[#stdout]):flatten():join("\n")
				local content = fmt("`%s`\n%s", spec.build_cmd(self.args), markdown.form_codeblock(output))
				return chat:add_tool_output(self, content, "")
			end
			return chat:add_tool_output(self, fmt("There was no output from the %s tool", spec.name), "")
		end,
	}

	return {
		name = spec.name,
		cmds = {},
		schema = schema,
		system_prompt = spec.system_prompt,
		handlers = vim.tbl_extend("force", default_handlers, spec.handlers or {}),
		output = vim.tbl_extend("force", default_output, spec.output or {}),
		gates = spec.gates,
	}
end

local M = {}

---@alias Palecore.CommandArgumentRule string|{ prefix?: string, literal?: string, hint?: string }

---@class Palecore.RunSpecificCommandOptions
---@field tool_name string
---@field tool_description string
---@field utility string
---@field leading_args? string[]
---@field trailing_args? string[]
---@field legal_args? boolean|Palecore.CommandArgumentRule[]
---@field illegal_args? Palecore.CommandArgumentRule[]
---@field stderr? boolean

local function shell_escape(argument) return vim.fn.shellescape(argument) end

local function normalize_argument_rule(rule)
	if type(rule) == "string" then return { literal = rule } end
	if type(rule) ~= "table" then return end

	if rule.prefix ~= nil and rule.literal ~= nil then
		vim.notify("Command argument rule cannot contain both prefix and literal", vim.log.levels.WARN)
		return
	end
	if type(rule.prefix) == "string" then return rule end
	if type(rule.literal) == "string" then return rule end
end

local function normalize_argument_rules(rules)
	local normalized_rules = {}
	for _, rule in ipairs(rules or {}) do
		local normalized_rule = normalize_argument_rule(rule)
		if normalized_rule then table.insert(normalized_rules, normalized_rule) end
	end
	return normalized_rules
end

local function matches_argument_rule(argument, rule)
	if rule.prefix then return vim.startswith(argument, rule.prefix) end
	return argument:find(rule.literal, 1, true) ~= nil
end

local function build_arguments(spec, agent_arguments)
	local arguments = vim.deepcopy(spec.leading_args)
	vim.list_extend(arguments, agent_arguments)
	vim.list_extend(arguments, spec.trailing_args)
	return arguments
end

local function find_illegal_argument(spec, agent_arguments)
	for _, agent_argument in ipairs(agent_arguments) do
		for _, illegal_rule in ipairs(spec.illegal_args) do
			if matches_argument_rule(agent_argument, illegal_rule) then return agent_argument, illegal_rule end
		end
	end
end

local function find_illegal_legal_argument(spec, agent_arguments)
	if spec.legal_args == nil or spec.legal_args == true then return end
	if spec.legal_args == false or #spec.legal_args == 0 then return agent_arguments[1] end

	for _, agent_argument in ipairs(agent_arguments) do
		local is_legal = false
		for _, legal_rule in ipairs(spec.legal_args) do
			if matches_argument_rule(agent_argument, legal_rule) then
				is_legal = true
				break
			end
		end
		if not is_legal then return agent_argument end
	end
end

---Builds a CodeCompanion tool for one unrestricted system command shape.
---@param spec Palecore.RunSpecificCommandOptions
---@return CodeCompanion.Tools.Tool
function M.make_specific_system_cmd_tool_spec(spec)
	spec.leading_args = spec.leading_args or {}
	spec.trailing_args = spec.trailing_args or {}
	if type(spec.legal_args) == "table" then spec.legal_args = normalize_argument_rules(spec.legal_args) end
	spec.illegal_args = normalize_argument_rules(spec.illegal_args)

	local has_agent_arguments = spec.legal_args ~= false and not (type(spec.legal_args) == "table" and #spec.legal_args == 0)
	local command_spec = {
		name = spec.tool_name,
		stderr = spec.stderr ~= false,
		description = spec.tool_description,
		schema = {
			properties = has_agent_arguments and {
				agent_arguments = {
					type = "array",
					description = "Optional arguments passed between fixed command arguments",
					items = { type = "string" },
				},
			} or {},
			required = {},
		},
		build_cmd = function(args)
			local arguments = build_arguments(spec, args.agent_arguments or {})
			return table.concat(
				vim.tbl_map(shell_escape, vim.iter({ spec.utility, arguments }):flatten():totable()),
				" "
			)
		end,
		handlers = {
			setup = function(self)
				local agent_arguments = self.args.agent_arguments or {}
				local illegal_argument, illegal_rule = find_illegal_argument(spec, agent_arguments)
				if illegal_argument then
					local hint = illegal_rule.hint and (" " .. illegal_rule.hint) or ""
					error(("Argument %q is forbidden.%s"):format(illegal_argument, hint))
				end

				local illegal_legal_argument = find_illegal_legal_argument(spec, agent_arguments)
				if illegal_legal_argument then
					error(("Argument %q is not allowed by legal_args"):format(illegal_legal_argument))
				end

				local arguments = build_arguments(spec, agent_arguments)
				local command = vim.iter({ spec.utility, arguments }):flatten():totable()
				self.cmds = { { cmd = vim.tbl_map(shell_escape, command) } }
			end,
		},
	}

	local tool = cmd_tool(command_spec)
	tool.description = spec.tool_description
	tool.opts = {
		require_approval_before = false,
		require_cmd_approval = false,
	}
	return tool
end

return M
