vim.opt_local.tabstop = 4

local go = require("config.go")
local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc }) end

map({ "n", "x" }, "<localleader>t", go.action("refactor.rewrite.addTags"), "Add struct tags")
map({ "n", "x" }, "<localleader>T", go.action("refactor.rewrite.removeTags"), "Remove struct tags")
map("n", "<localleader>f", go.action("refactor.rewrite.fillStruct"), "Fill struct")
map("n", "<localleader>s", go.action("refactor.rewrite.fillSwitch"), "Fill switch")
map("n", "<localleader>a", go.action("source.addTest"), "Add test for function")
map("n", "<localleader>o", go.action("source.toggleCompilerOptDetails"), "Toggle compiler opt details")
map("n", "<localleader>A", go.action("source.assembly"), "Browse assembly")
map("n", "<localleader>m", go.mod_tidy, "go mod tidy")
map("n", "<localleader>d", function()
  require("plugins.debug").setup()
  require("dap-go").debug_test()
end, "Debug test at cursor")
