return {
  -- In-buffer markdown rendering (headings, code blocks, tables, checkboxes, etc.)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
  },

  -- Live browser preview with :MarkdownPreviewToggle
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = "cd app && npx --yes yarn install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },
}
