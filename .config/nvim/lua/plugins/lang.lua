local pack = require("config.pack")
local plugins = require("plugins")

-- Read by rustaceanvim when the first Rust buffer opens; it owns rust-analyzer
-- (resolved from PATH, i.e. the rustup proxy matching the active toolchain).
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        -- Separate target dir: RA's checks stop blocking `cargo build` in
        -- another pane on the build-dir lock, at the cost of extra disk.
        cargo = { targetDir = true },
        check = { command = "clippy", extraArgs = { "--no-deps" } },
        inlayHints = {
          lifetimeElisionHints = { enable = "skip_trivial" },
          closureReturnTypeHints = { enable = "with_block" },
        },
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
  })
end, "Cargo.toml")

-- Its plugin file attaches to the current buffer when loaded late.
pack.on("FileType", function() plugins.load("markdown") end, "markdown")
