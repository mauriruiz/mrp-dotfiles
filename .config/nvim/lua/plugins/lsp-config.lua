return {
  -- Mason: install binaries LSP
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason bridge
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "gopls",
          "rust_analyzer",
          "ts_ls",

          -- HTML / CSS
          "html",
          "cssls",
          "emmet_ls",

          -- JSON
          "jsonls",

          -- C#
          "omnisharp",

          -- Markdown
          "marksman",
        },
      })
    end,
  },

  -- LSP core (API nueva Neovim 0.11)
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Lua
      vim.lsp.config.lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            semantic = { enable = true },
          },
        },
      }

      -- Rust
      vim.lsp.config.rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            semanticHighlighting = {
              punctuation = { enable = true },
              operator = { specialization = { enable = true } },
            },
          },
        },
      }

      -- TypeScript — semantic tokens on by default, enable inlay hints
      vim.lsp.config.ts_ls = {
        settings = {
          typescript = { suggest = { completeFunctionCalls = true } },
          javascript = { suggest = { completeFunctionCalls = true } },
        },
      }

      -- Go
      vim.lsp.config.gopls = {
        settings = {
          gopls = {
            semanticTokens = true,
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
      }

      -- C#
      vim.lsp.config.omnisharp = {
        cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
      }

      -- Enable servers
      vim.lsp.enable("omnisharp")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("gopls")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("html")
      vim.lsp.enable("cssls")
      vim.lsp.enable("emmet_ls")
      vim.lsp.enable("jsonls")
      vim.lsp.enable("marksman")

      -- Keymaps
      vim.keymap.set("n", "K", vim.lsp.buf.hover)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "gr", function()
        require("telescope.builtin").lsp_references()
      end, { desc = "Go to references (Telescope)" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
    end,
  }
}
