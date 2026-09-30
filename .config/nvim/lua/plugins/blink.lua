return {
  "saghen/blink.cmp",
  version = "1.*",
  lazy = true, -- loaded by nvim-lspconfig so capabilities exist before servers start
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      list = { selection = { auto_insert = false } },
      menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
      documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
