return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>C", group = "crates" },
      { "<leader>d", group = "debug" },
      { "<leader>f", group = "find" },
      { "<leader>h", group = "hunks" },
      { "<leader>r", group = "rust" },
      { "<leader>t", group = "terminal" },
      { "<leader>u", group = "ui" },
    },
  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
  },
}
