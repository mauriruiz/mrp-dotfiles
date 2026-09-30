return {
  -- Mason: install LSP/DAP/formatter binaries on demand.
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
    opts = {},
  },

  -- Mason ↔ lspconfig bridge: ensures servers are installed before LSP attaches.
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls", "gopls", "ts_ls",
        "html", "cssls", "emmet_ls",
        "jsonls", "omnisharp", "marksman",
      },
      -- rustaceanvim owns the rust client; suppress mason-lspconfig auto-enable
      -- so we don't end up with two rust-analyzer instances per buffer.
      automatic_enable = { exclude = { "rust_analyzer" } },
    },
  },

  -- LSP core (Neovim 0.11 native API).
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    -- blink.cmp registers its capabilities on vim.lsp.config("*") when loaded.
    dependencies = { "saghen/blink.cmp" },
    config = function()
      vim.lsp.config.lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            semantic = { enable = true },
            workspace = { checkThirdParty = false },
          },
        },
      }

      vim.lsp.config.ts_ls = {
        settings = {
          typescript = { suggest = { completeFunctionCalls = true } },
          javascript = { suggest = { completeFunctionCalls = true } },
        },
      }

      vim.lsp.config.gopls = {
        settings = {
          gopls = {
            semanticTokens = true,
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
      }

      vim.lsp.config.omnisharp = {
        cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
      }

      for _, server in ipairs({
        "lua_ls", "gopls", "ts_ls",
        "html", "cssls", "emmet_ls",
        "jsonls", "omnisharp", "marksman",
      }) do
        vim.lsp.enable(server)
      end

      -- Buffer-local keymaps only when an LSP attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buf = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
          end
          map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
          map("n", "gd", vim.lsp.buf.definition, "Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Declaration")
          map("n", "gi", vim.lsp.buf.implementation, "Implementation")
          -- nowait: skip the timeout from 0.11's default gr* maps.
          vim.keymap.set("n", "gr", function() require("telescope.builtin").lsp_references() end,
            { buffer = buf, desc = "References", nowait = true })
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
          map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
          map("n", "<leader>uh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
          end, "Toggle inlay hints")

          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end
        end,
      })
    end,
  },
}
