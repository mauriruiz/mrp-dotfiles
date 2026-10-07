local function rust(cmd)
  return function() vim.cmd.RustLsp(cmd) end
end
local function debug(cmd)
  return function()
    require("plugins.debug").setup()
    vim.cmd.RustLsp(cmd)
  end
end
local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc }) end

map("K", rust({ "hover", "actions" }), "Hover actions")

-- Shared with Go (after/ftplugin/go.lua): same key, same meaning.
map("<localleader>e", rust({ "renderDiagnostic", "current" }), "Show error")
map("<localleader>E", rust({ "explainError", "current" }), "Explain error (rustc --explain)")
map("<localleader>d", debug("debug"), "Debug item under cursor")
map("<localleader>D", debug("debuggables"), "Pick what to debug")
map("<localleader>r", rust("runnables"), "Pick what to run")
map("<localleader>a", rust("codeAction"), "Code action (grouped)")
map("<localleader>o", rust("openDocs"), "Open docs.rs")
map("<localleader>c", rust("openCargo"), "Open Cargo.toml")

-- Rust only.
map("<localleader>m", rust("expandMacro"), "Expand macro")
map("<localleader>p", rust("parentModule"), "Parent module")
map("<localleader>j", rust("joinLines"), "Join lines")
