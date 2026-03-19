return {
  'edmondop/cedar.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('cedar').setup()
  end,
}
