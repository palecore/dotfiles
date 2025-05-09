local function toggle_yadm()
	local yadm_git_dir = vim.env.HOME .. "/.local/share/yadm/repo.git"
	local yadm_work_tree = assert(vim.env.HOME)
	if vim.env.GIT_DIR == yadm_git_dir and vim.env.GIT_WORK_TREE == yadm_work_tree then
		vim.env.GIT_DIR = nil
		vim.env.GIT_WORK_TREE = nil
		print("no yadm")
	else
		vim.env.GIT_DIR = yadm_git_dir
		vim.env.GIT_WORK_TREE = yadm_work_tree
		print("yadm")
	end
end

---@type LazySpec
return {
	name = "custom-yadm",
	dir = "/dev/null", -- Fake plugin - all logic contained here.
	keys = {
		{
			"<leader>ty",
			toggle_yadm,
			id = "ty",
			desc = "Toggle yadm environment",
		},
	},
}
