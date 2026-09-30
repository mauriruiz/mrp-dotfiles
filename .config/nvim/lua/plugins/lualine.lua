return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "gruvbox",
      globalstatus = true,
      component_separators = "",
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = { "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { { "mode", separator = { left = "" } } },
      lualine_b = { "branch", "diff" },
      lualine_c = { { "filename", path = 1, symbols = { modified = "●", readonly = "" } } },
      lualine_x = { "diagnostics", { "lsp_status", symbols = { done = "" } }, "filetype" },
      lualine_y = { "progress" },
      lualine_z = { { "location", separator = { right = "" } } },
    },
  },
}
