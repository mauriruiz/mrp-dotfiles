local opt = vim.opt

-- Indent
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.smartindent = true

-- UI
opt.number = true
opt.relativenumber = true
opt.cmdheight = 0
opt.splitright = true
opt.splitbelow = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.cursorline = true
opt.showmode = false
opt.laststatus = 3
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.pumheight = 12
opt.fillchars = { eob = " " }
opt.undofile = true
opt.confirm = true

-- Performance
opt.updatetime = 200
opt.timeoutlen = 400
opt.lazyredraw = false -- harmful with noice/lualine; default off is best
opt.synmaxcol = 300

-- Search
opt.ignorecase = true
opt.smartcase = true

opt.clipboard = "unnamedplus"

-- Diagnostics (modern API; replaces deprecated sign_define).
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●" },
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN]  = "",
      [vim.diagnostic.severity.INFO]  = "",
      [vim.diagnostic.severity.HINT]  = "",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Core keymaps
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Window navigation
map("n", "<C-h>", "<C-w>h", { silent = true })
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })
map("n", "<C-l>", "<C-w>l", { silent = true })
