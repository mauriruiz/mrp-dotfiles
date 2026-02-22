return {
  {
    'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require("telescope.builtin")
      local function live_grep_literal()
        builtin.live_grep({
          additional_args = function()
            return { "--fixed-strings" }
          end,
        })
      end

      vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Find files" })
      vim.keymap.set('n', '<leader>fg', live_grep_literal, { desc = "Live grep (literal)" })
      vim.keymap.set('n', '<leader>fG', builtin.live_grep, { desc = "Live grep (regex)" })
    end,
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }
          }
        }
      })
      require("telescope").load_extension("ui-select")
    end
  },
}
