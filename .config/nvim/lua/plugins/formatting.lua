return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "Format" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ lsp_format = "fallback" }) end,
      desc = "Format buffer (conform)",
    },
  },
  opts = {
    default_format_opts = { lsp_format = "never" },
    -- ponytail: save-format only where the formatter is a language standard.
    format_on_save = function(buf)
      if vim.tbl_contains({ "rust", "go" }, vim.bo[buf].filetype) then
        return { timeout_ms = 1000 }
      end
    end,
    formatters_by_ft = {
      rust = { "rustfmt" },
      go = { "gofmt" },
      cs = { "csharpier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      json = { "prettier" },
    },
  },
}
