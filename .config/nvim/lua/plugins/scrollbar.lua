return {
  {
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    dependencies = {
      "kevinhwang91/nvim-hlslens",
      "lewis6991/gitsigns.nvim",
    },
    config = function()
      require("scrollbar").setup({
        show = true,
        hide_if_all_visible = true,
      })

      local diagnostic = require("scrollbar.handlers.diagnostic")
      local search     = require("scrollbar.handlers.search")
      local gitsigns   = require("scrollbar.handlers.gitsigns")

      diagnostic.setup()
      search.setup()
      gitsigns.setup()

      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          diagnostic.setup()
        end,
      })
    end,
  },
}
