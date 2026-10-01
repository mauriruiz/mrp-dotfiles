local pack = require("config.pack")
local plugins = require("plugins")

-- Read by rustaceanvim when the first Rust buffer opens; it owns rust-analyzer
-- (resolved from PATH, i.e. the rustup proxy matching the active toolchain).
vim.g.rustaceanvim = {
  tools = { hover_actions = { auto_focus = true } },
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        -- Separate target dir: RA's checks stop blocking `cargo build` in
        -- another pane on the build-dir lock, at the cost of extra disk.
        cargo = { features = "all", targetDir = true },
        check = { command = "clippy", extraArgs = { "--no-deps" } },
        procMacro = {
          ignored = {
            ["async-trait"] = { "async_trait" },
            ["napi-derive"] = { "napi" },
            ["async-recursion"] = { "async_recursion" },
          },
        },
        inlayHints = {
          bindingModeHints = { enable = true },
          chainingHints = { enable = true },
          closingBraceHints = { enable = true, minLines = 10 },
          closureReturnTypeHints = { enable = "always" },
          lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
          parameterHints = { enable = true },
          typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
        },
        semanticHighlighting = {
          punctuation = { enable = true },
          operator = { specialization = { enable = true } },
        },
        files = { exclude = { ".direnv", ".git", "node_modules", "target" } },
        lens = { implementations = { enable = false } },
      },
    },
  },
}

pack.on("BufRead", function()
  plugins.load("crates")
  require("crates").setup({
    lsp = { enabled = true, actions = true, completion = true, hover = true },
    completion = { crates = { enabled = true } },
    on_attach = function(buf)
      local crates = require("crates")
      local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc }) end
      map("<leader>Ct", crates.toggle, "Toggle crates")
      map("<leader>Cr", crates.reload, "Reload crates")
      map("<leader>Cv", crates.show_versions_popup, "Show versions")
      map("<leader>Cf", crates.show_features_popup, "Show features")
      map("<leader>Cu", crates.update_crate, "Update crate")
      map("<leader>CU", crates.upgrade_crate, "Upgrade crate")
      map("<leader>Ca", crates.upgrade_all_crates, "Upgrade all crates")
    end,
  })
end, "Cargo.toml")

-- Its plugin file attaches to the current buffer when loaded late.
pack.on("FileType", function() plugins.load("markdown") end, "markdown")
