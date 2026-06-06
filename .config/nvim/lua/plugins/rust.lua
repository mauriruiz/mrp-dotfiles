return {
  -- rustaceanvim: modern rust-analyzer wrapper (runnables, debuggables, expand macro, test runner).
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    init = function()
      vim.g.rustaceanvim = {
        tools = {
          hover_actions = { auto_focus = true },
          float_win_config = { border = "rounded" },
        },
        server = {
          -- Always use the rustup proxy at ~/.cargo/bin/rust-analyzer. It auto-selects
          -- the rust-analyzer matching the active toolchain (honours rust-toolchain.toml),
          -- so it stays version-locked to rustc across `rustup update`. Avoids the stale
          -- mason binary that rustaceanvim would otherwise prefer (proc-macro ABI skew →
          -- derive macros like thiserror::Error fail to expand).
          cmd = { vim.fn.expand("~/.cargo/bin/rust-analyzer") },
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = {
                enable = true,
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
              files = {
                excludeDirs = { ".direnv", ".git", "node_modules", "target" },
              },
            },
          },
        },
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function(ev)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("n", "<leader>rr", function() vim.cmd.RustLsp("runnables") end, "Rust runnables")
          map("n", "<leader>rt", function() vim.cmd.RustLsp({ "testables" }) end, "Rust testables")
          map("n", "<leader>rm", function() vim.cmd.RustLsp("expandMacro") end, "Expand macro")
          map("n", "<leader>rc", function() vim.cmd.RustLsp("openCargo") end, "Open Cargo.toml")
          map("n", "<leader>rp", function() vim.cmd.RustLsp("parentModule") end, "Parent module")
          map("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Rust hover actions")
        end,
      })
    end,
  },

  -- crates.nvim: Cargo.toml completion, version hints, upgrade actions.
  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    config = function(_, opts)
      require("crates").setup(opts)
      vim.api.nvim_create_autocmd("BufRead", {
        pattern = "Cargo.toml",
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          local crates = require("crates")
          map("<leader>Ct", crates.toggle, "Toggle crates")
          map("<leader>Cr", crates.reload, "Reload crates")
          map("<leader>Cv", crates.show_versions_popup, "Show versions")
          map("<leader>Cf", crates.show_features_popup, "Show features")
          map("<leader>Cu", crates.update_crate, "Update crate")
          map("<leader>CU", crates.upgrade_crate, "Upgrade crate")
          map("<leader>Ca", crates.upgrade_all_crates, "Upgrade all crates")
        end,
      })
    end,
  },
}
