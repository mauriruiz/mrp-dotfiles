return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      diagnostics = { globals = { "Snacks", "MiniIcons", "MiniStatusline" } },
      completion = { callSnippet = "Replace" },
      hint = { enable = true, arrayIndex = "Disable" },
      telemetry = { enable = false },
    },
  },
}
