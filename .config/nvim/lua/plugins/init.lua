-- Every third-party dependency, in one place. `eager` is on the runtimepath
-- from startup; each `lazy` group is added the first time it is needed.
local function gh(repo) return "https://github.com/" .. repo end

local M = {}

M.eager = {
  gh("ellisonleao/gruvbox.nvim"),
  gh("folke/snacks.nvim"), -- picker, explorer, terminal, notifier, lazygit, input
  gh("nvim-mini/mini.nvim"), -- icons, statusline, surround
  gh("folke/which-key.nvim"),
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  gh("neovim/nvim-lspconfig"), -- server definitions for vim.lsp.enable
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  gh("rafamadriz/friendly-snippets"), -- read by blink.cmp
  gh("lewis6991/gitsigns.nvim"),
  { src = gh("mrcjkb/rustaceanvim"), version = vim.version.range("9.*") },
}

M.lazy = {
  mason = { gh("mason-org/mason.nvim") },
  format = { gh("stevearc/conform.nvim") },
  lint = { gh("mfussenegger/nvim-lint") },
  replace = { gh("MagicDuck/grug-far.nvim") },
  tree = {
    gh("nvim-lua/plenary.nvim"),
    gh("MunifTanjim/nui.nvim"),
    { src = gh("nvim-neo-tree/neo-tree.nvim"), version = vim.version.range("3.*") },
  },
  crates = { { src = gh("saecki/crates.nvim"), version = "stable" } },
  markdown = { gh("MeanderingProgrammer/render-markdown.nvim") },
  test = {
    gh("nvim-neotest/nvim-nio"),
    gh("nvim-lua/plenary.nvim"),
    gh("nvim-neotest/neotest"),
    { src = gh("fredrikaverpil/neotest-golang"), version = vim.version.range("2.*") },
  },
  debug = {
    gh("mfussenegger/nvim-dap"),
    gh("igorlfs/nvim-dap-view"),
    gh("leoluz/nvim-dap-go"),
  },
}

local loaded = {}
function M.load(group)
  if loaded[group] then return end
  loaded[group] = true
  vim.pack.add(M.lazy[group], { confirm = false })
end

function M.names()
  local names = {}
  local specs = vim.list_extend({}, M.eager)
  for _, group in pairs(M.lazy) do
    vim.list_extend(specs, group)
  end
  for _, spec in ipairs(specs) do
    local src = type(spec) == "string" and spec or spec.src
    names[type(spec) == "table" and spec.name or src:match("[^/]+$")] = true
  end
  return names
end

vim.pack.add(M.eager, { confirm = false })

return M
