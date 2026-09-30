return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    contrast = "hard",
    overrides = {
      SignColumn = { link = "Normal" },
      LspInlayHint = { link = "Comment" },
      -- Bordered floats/menus share the editor background instead of a grey slab.
      NormalFloat = { link = "Normal" },
      Pmenu = { link = "Normal" },
      SnacksIndentScope = { fg = "#7c6f64" },
    },
  },
  config = function(_, opts)
    require("gruvbox").setup(opts)
    vim.cmd.colorscheme("gruvbox")
  end,
}
