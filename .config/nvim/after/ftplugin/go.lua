vim.opt_local.tabstop = 4

local go = require("config.go")
local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc }) end
local function debug(fn)
  return function() require("plugins.debug").setup()[fn]() end
end

-- Shared with Rust (after/ftplugin/rust.lua): same key, same meaning.
map("n", "<localleader>e", vim.diagnostic.open_float, "Show error")
map("n", "<localleader>E", go.explain_error, "Explain error (docs)")
map("n", "<localleader>d", function()
  require("plugins.debug").setup()
  require("dap-go").debug_test()
end, "Debug test under cursor")
map("n", "<localleader>D", debug("continue"), "Pick what to debug")
map("n", "<localleader>r", go.run, "Run package (go run)")
map({ "n", "x" }, "<localleader>a", vim.lsp.buf.code_action, "Code action")
map("n", "<localleader>o", go.action("source.doc"), "Open docs")
map("n", "<localleader>c", go.open_mod, "Open go.mod")

-- Go only.
map({ "n", "x" }, "<localleader>t", go.action("refactor.rewrite.addTags"), "Add struct tags")
map({ "n", "x" }, "<localleader>T", go.action("refactor.rewrite.removeTags"), "Remove struct tags")
map("n", "<localleader>f", go.action("refactor.rewrite.fillStruct"), "Fill struct")
map("n", "<localleader>s", go.action("refactor.rewrite.fillSwitch"), "Fill switch")
map("n", "<localleader>g", go.action("source.addTest"), "Generate test for function")
map("n", "<localleader>m", go.mod_tidy, "go mod tidy")
map("n", "<localleader>i", go.action("source.toggleCompilerOptDetails"), "Toggle compiler opt details")
map("n", "<localleader>A", go.action("source.assembly"), "Browse assembly")
