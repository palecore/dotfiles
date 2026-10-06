local helpers = require("codecompanion.interactions.chat.tools.builtin.helpers")
local markdown = require("codecompanion.utils.markdown")

local fmt = string.format

---Create a command-line tool from a specification table.
---
---This factory function returns a complete CodeCompanion tool table that
---executes shell commands. Users provide a minimal spec and get a fully
---functional tool with schema, approval prompts, and output handling.
---
---@param dependencies? { add_tool_output?: fun(chat: table, tool: table, for_llm: string, for_user: string), form_codeblock?: fun(content: string, opts?: table): string, notify?: fun(message: string, level: number), shell_escape?: fun(argument: string): string }
---@return CodeCompanion.Tools.Tool
local function cmd_tool(spec, dependencies)
	dependencies = dependencies or {}
	local add_tool_output = dependencies.add_tool_output
		or function(chat, tool, for_llm, for_user)
			return chat:add_tool_output(tool, for_llm, for_user)
		end
	local form_codeblock = dependencies.form_codeblock or markdown.form_codeblock
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
		cmd_string = function(self, meta)
			return spec.build_cmd(self.args)
		end,

		---@param self CodeCompanion.Tools.Tool
		---@param stderr table The error output from the command
		---@param meta { tools: CodeCompanion.Tools, cmd: table }
		error = function(self, stderr, meta)
			if stderr and spec.stderr ~= false then
				local chat = meta.tools.chat
				local cmd_string = spec.build_cmd(self.args)
				local errors = vim.iter(stderr):flatten():join("\n")

				local content = form_codeblock(errors, { ft = "txt" })
				local exit_code = meta.cmd and meta.cmd.code
				local status = exit_code and fmt(" with exit code %d", exit_code) or ""

				local llm_output = fmt("Command `%s` failed%s:\n%s", cmd_string, status, content)
				local user_output = fmt("`%s` failed%s\n%s", cmd_string, status, content)

				return add_tool_output(chat, self, llm_output, user_output)
			end
		end,

		---Prompt the user to approve the execution of the command
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools }
		---@return string
		prompt = function(self, meta)
			return fmt("Run the command `%s`?", spec.build_cmd(self.args))
		end,

		---Rejection message back to the LLM
		---@param self CodeCompanion.Tools.Tool
		---@param meta { tools: CodeCompanion.Tools, cmd: string, opts: table }
		---@return nil
		rejected = function(self, meta)
			local content = fmt("The user rejected the execution of the `%s` tool", spec.name)
			local rejection_meta = type(meta) == "table" and meta or {}
			rejection_meta = vim.tbl_extend("force", { message = content }, rejection_meta)
			helpers.rejected(self, rejection_meta)
		end,

		---@param self CodeCompanion.Tools.Tool
		---@param stdout table|nil The output from the tool
		---@param meta { tools: table, cmd: table }
		---@return nil
		success = function(self, stdout, meta)
			local chat = meta.tools.chat
			if stdout then
				local output = vim.iter(stdout[#stdout]):flatten():join("\n")
				local content = fmt("`%s`\n%s", spec.build_cmd(self.args), form_codeblock(output))
				return add_tool_output(chat, self, content, "")
			end
			return add_tool_output(chat, self, fmt("There was no output from the %s tool", spec.name), "")
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

local function shell_escape(argument)
	return vim.fn.shellescape(argument)
end

local function is_string_list(value)
	if type(value) ~= "table" or not vim.islist(value) then
		return false
	end
	return vim.iter(value):all(function(argument)
		return type(argument) == "string"
	end)
end

local function is_argument_rule(rule)
	if type(rule) == "string" then
		return true
	end
	if type(rule) ~= "table" or vim.islist(rule) then
		return false
	end
	if rule.prefix ~= nil and rule.literal ~= nil then
		return false
	end
	if type(rule.prefix) ~= "string" and type(rule.literal) ~= "string" then
		return false
	end
	return rule.hint == nil or type(rule.hint) == "string"
end

local function is_argument_rule_list(rules)
	if type(rules) ~= "table" or not vim.islist(rules) then
		return false
	end
	return vim.iter(rules):all(is_argument_rule)
end

local function get_config_error(spec)
	if type(spec) ~= "table" then
		return "spec must be a table"
	end
	for _, field in ipairs({ "tool_name", "tool_description", "utility" }) do
		if type(spec[field]) ~= "string" or spec[field] == "" then
			return field .. " must be a non-empty string"
		end
	end
	for _, field in ipairs({ "leading_args", "trailing_args" }) do
		if spec[field] ~= nil and not is_string_list(spec[field]) then
			return field .. " must be a list of strings"
		end
	end
	if
		spec.legal_args ~= nil
		and type(spec.legal_args) ~= "boolean"
		and not is_argument_rule_list(spec.legal_args)
	then
		return "legal_args must be a boolean or a list of argument rules"
	end
	if spec.illegal_args ~= nil and not is_argument_rule_list(spec.illegal_args) then
		return "illegal_args must be a list of argument rules"
	end
	if spec.stderr ~= nil and type(spec.stderr) ~= "boolean" then
		return "stderr must be a boolean"
	end
end

local function normalize_argument_rule(rule)
	if type(rule) == "string" then
		return { literal = rule }
	end
	if type(rule) ~= "table" then
		return
	end

	if rule.prefix ~= nil and rule.literal ~= nil then
		vim.notify("Command argument rule cannot contain both prefix and literal", vim.log.levels.WARN)
		return
	end
	if type(rule.prefix) == "string" then
		return rule
	end
	if type(rule.literal) == "string" then
		return rule
	end
end

local function normalize_argument_rules(rules)
	local normalized_rules = {}
	for _, rule in ipairs(rules or {}) do
		local normalized_rule = normalize_argument_rule(rule)
		if normalized_rule then
			table.insert(normalized_rules, normalized_rule)
		end
	end
	return normalized_rules
end

local function matches_argument_rule(argument, rule)
	if rule.prefix then
		return vim.startswith(argument, rule.prefix)
	end
	return argument:find(rule.literal, 1, true) ~= nil
end

local function describe_argument_rule(rule)
	local match = rule.prefix and ("starts with " .. string.format("%q", rule.prefix))
		or ("contains " .. string.format("%q", rule.literal))
	local hint = rule.hint and (" (" .. rule.hint .. ")") or ""
	return match .. hint
end

local function describe_argument_rules(rules)
	return table.concat(vim.tbl_map(describe_argument_rule, rules), "; ")
end

local function format_argument_list(arguments)
	local formatted_arguments = vim.tbl_map(function(argument)
		return string.format("%q", argument)
	end, arguments)
	return "[" .. table.concat(formatted_arguments, ", ") .. "]"
end

local function get_tool_discovery_description(spec)
	local sections = {
		spec.tool_description,
		("Command utility: %q. Fixed leading arguments: %s. Fixed trailing arguments: %s. Supply only variable arguments in agent_arguments; tool inserts them between fixed argument lists."):format(
			spec.utility,
			format_argument_list(spec.leading_args),
			format_argument_list(spec.trailing_args)
		),
	}
	if spec.legal_args == false or (type(spec.legal_args) == "table" and #spec.legal_args == 0) then
		table.insert(
			sections,
			"Do not provide agent_arguments; this tool accepts no agent-supplied arguments."
		)
	elseif type(spec.legal_args) == "table" then
		table.insert(
			sections,
			"Every agent argument must match at least one legal rule: "
				.. describe_argument_rules(spec.legal_args)
				.. "."
		)
	else
		table.insert(sections, "Agent arguments are unrestricted except for the forbidden rules below.")
	end
	if #spec.illegal_args > 0 then
		table.insert(
			sections,
			"Never use arguments matching these forbidden rules: "
				.. describe_argument_rules(spec.illegal_args)
				.. "."
		)
	end
	return table.concat(sections, " ")
end

local function get_agent_arguments(args)
	local agent_arguments = type(args) == "table" and args.agent_arguments
	if type(agent_arguments) ~= "table" then
		return {}
	end
	return agent_arguments
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
			if matches_argument_rule(agent_argument, illegal_rule) then
				return agent_argument, illegal_rule
			end
		end
	end
end

local function find_illegal_legal_argument(spec, agent_arguments)
	if spec.legal_args == nil or spec.legal_args == true then
		return
	end
	if spec.legal_args == false or #spec.legal_args == 0 then
		return agent_arguments[1]
	end

	for _, agent_argument in ipairs(agent_arguments) do
		local is_legal = false
		for _, legal_rule in ipairs(spec.legal_args) do
			if matches_argument_rule(agent_argument, legal_rule) then
				is_legal = true
				break
			end
		end
		if not is_legal then
			return agent_argument
		end
	end
end

local function report_invalid_arguments(self, meta, dependencies, message)
	local chat = meta.tools.chat
	local llm_output = "Command was not run: " .. message
	local user_output = "Command not run\n" .. message
	dependencies.add_tool_output(chat, self, llm_output, user_output)
end

---Builds a CodeCompanion tool for one unrestricted system command shape.
---@param spec Palecore.RunSpecificCommandOptions
---@param dependencies? { add_tool_output?: fun(chat: table, tool: table, for_llm: string, for_user: string), form_codeblock?: fun(content: string, opts?: table): string }
---@return CodeCompanion.Tools.Tool
function M.make_specific_system_cmd_tool_spec(spec, dependencies)
	dependencies = dependencies or {}
	dependencies.notify = dependencies.notify or vim.notify
	dependencies.shell_escape = dependencies.shell_escape or shell_escape
	local config_error = get_config_error(spec)
	if config_error then
		dependencies.notify(
			"Invalid custom command tool configuration: " .. config_error,
			vim.log.levels.ERROR
		)
		return
	end
	dependencies.add_tool_output = dependencies.add_tool_output
		or function(chat, tool, for_llm, for_user)
			return chat:add_tool_output(tool, for_llm, for_user)
		end
	spec.leading_args = spec.leading_args or {}
	spec.trailing_args = spec.trailing_args or {}
	if type(spec.legal_args) == "table" then
		spec.legal_args = normalize_argument_rules(spec.legal_args)
	end
	spec.illegal_args = normalize_argument_rules(spec.illegal_args)

	local has_agent_arguments = spec.legal_args ~= false
		and not (type(spec.legal_args) == "table" and #spec.legal_args == 0)
	local discovery_description = get_tool_discovery_description(spec)
	local command_spec = {
		name = spec.tool_name,
		stderr = spec.stderr ~= false,
		description = discovery_description,
		system_prompt = discovery_description,
		schema = {
			properties = has_agent_arguments and {
				agent_arguments = {
					type = "array",
					description = "Optional arguments passed between fixed command arguments",
					items = { type = "string" },
				},
			} or vim.empty_dict(),
			required = {},
		},
		build_cmd = function(args)
			local arguments = build_arguments(spec, get_agent_arguments(args))
			return table.concat(
				vim.tbl_map(
					dependencies.shell_escape,
					vim.iter({ spec.utility, arguments }):flatten():totable()
				),
				" "
			)
		end,
		handlers = {
			setup = function(self, meta)
				local agent_arguments = get_agent_arguments(self.args)
				local illegal_argument, illegal_rule = find_illegal_argument(spec, agent_arguments)

				if illegal_argument then
					report_invalid_arguments(
						self,
						meta,
						dependencies,
						("Argument %q is forbidden because it matches a rule: %s."):format(
							illegal_argument,
							describe_argument_rule(illegal_rule)
						)
					)
					return
				end

				local illegal_legal_argument = find_illegal_legal_argument(spec, agent_arguments)
				if illegal_legal_argument then
					local allowed = type(spec.legal_args) == "table"
							and describe_argument_rules(spec.legal_args)
						or "no agent arguments are allowed"
					local message = ("Argument %q is not allowed. %s"):format(illegal_legal_argument, allowed)
					report_invalid_arguments(self, meta, dependencies, message)
					return
				end

				local arguments = build_arguments(spec, agent_arguments)
				local command = vim.iter({ spec.utility, arguments }):flatten():totable()
				self.cmds = { { cmd = vim.tbl_map(dependencies.shell_escape, command) } }
			end,
		},
	}

	local tool = cmd_tool(command_spec, dependencies)
	tool.description = spec.tool_description
	tool.opts = {
		require_approval_before = false,
		require_cmd_approval = false,
	}
	return tool
end

return M
