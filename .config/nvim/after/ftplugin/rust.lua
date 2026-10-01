local function rust(cmd)
  return function() vim.cmd.RustLsp(cmd) end
end
local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc }) end

map("K", rust({ "hover", "actions" }), "Hover actions")
map("<localleader>a", rust("codeAction"), "Code action (grouped)")
map("<localleader>r", rust("runnables"), "Runnables")
map("<localleader>t", rust("testables"), "Testables")
map("<localleader>d", function()
  require("plugins.debug").setup()
  vim.cmd.RustLsp("debuggables")
end, "Debuggables")
map("<localleader>m", rust("expandMacro"), "Expand macro")
map("<localleader>e", rust({ "explainError", "current" }), "Explain error")
map("<localleader>D", rust({ "renderDiagnostic", "current" }), "Render diagnostic")
map("<localleader>c", rust("openCargo"), "Open Cargo.toml")
map("<localleader>p", rust("parentModule"), "Parent module")
map("<localleader>o", rust("openDocs"), "Open docs.rs")
map("<localleader>j", rust("joinLines"), "Join lines")
