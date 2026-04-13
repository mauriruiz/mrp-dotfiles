vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cmdheight = 0
vim.opt.clipboard = "unnamedplus"

vim.g.maplocalleader = "\\"
vim.g.mapleader = " "

vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    prefix = "●",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Iconos de signos
vim.fn.sign_define("DiagnosticSignError", {text = "", texthl="DiagnosticSignError"})
vim.fn.sign_define("DiagnosticSignWarn",  {text = "", texthl="DiagnosticSignWarn"})
vim.fn.sign_define("DiagnosticSignInfo",  {text = "", texthl="DiagnosticSignInfo"})
vim.fn.sign_define("DiagnosticSignHint",  {text = "", texthl="DiagnosticSignHint"})

vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { silent = true })
vim.opt.splitright = true
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
