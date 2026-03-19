return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "html",
        "css",

        -- frontend
        "javascript",
        "typescript",
        "tsx",
        "json",

        -- backend
        "rust",
        "go",
        "gomod",
        "gosum",
        "zig",
        "lua",
        "c_sharp",
        "python",

        -- markup / config
        "markdown",
        "markdown_inline",
        "yaml",
        "toml",

        -- shell / infra
        "bash",
        "dockerfile",

        -- nvim
        "vim",
        "vimdoc",
        "regex",
        "query",
      },
      highlight = {
        enable = true,
      },
      indent = { enable = true },
    })
  end,
}
