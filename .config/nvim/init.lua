vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

for _, provider in ipairs({ "python3", "ruby", "perl", "node" }) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end
for _, plugin in ipairs({ "gzip", "tar", "tarPlugin", "zip", "zipPlugin", "tutor_mode_plugin", "netrw", "netrwPlugin" }) do
  vim.g["loaded_" .. plugin] = 1
end

require("config.options")
require("config.pack")
require("plugins")

require("plugins.ui")
require("plugins.editor")
require("plugins.git")
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.lang")
require("plugins.test")
require("plugins.debug")

require("config.lsp")
require("config.keymaps")
require("config.autocmds")
