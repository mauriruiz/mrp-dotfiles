local M = {}

M.defaults = {
  keymaps = {
    open = "<leader>gg",
    stage = "s",
    unstage = "u",
    stage_hunk = "hs",
    unstage_hunk = "hu",
    commit = "c",
    push = "P",
    pull = "L",
    branch = "b",
    new_branch = "n",
    refresh = "r",
    close = "q",
    toggle_section = "<CR>",
    focus_diff = "<Tab>",
  },
  layout = {
    status_width = 42,
  },
  icons = {
    staged = "✓",
    modified = "~",
    added = "+",
    deleted = "-",
    untracked = "?",
    renamed = "→",
    branch = "",
    section_open = "▼",
    section_closed = "▶",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
