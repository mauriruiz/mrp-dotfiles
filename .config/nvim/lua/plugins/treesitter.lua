local pack = require("config.pack")

vim.filetype.add({ extension = { cedar = "cedar" } })
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").cedar = {
      install_info = { url = "https://github.com/chrnorm/tree-sitter-cedar", queries = "queries" },
    }
  end,
})

local parsers = {
  "go",
  "gomod",
  "gosum",
  "gowork",
  "gotmpl",
  "proto",
  "rust",
  "toml",
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query",
  "regex",
  "bash",
  "make",
  "dockerfile",
  "yaml",
  "json",
  "sql",
  "hcl",
  "terraform",
  "cedar",
  "markdown",
  "markdown_inline",
  "diff",
  "git_config",
  "gitcommit",
  "git_rebase",
  "gitignore",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "c_sharp",
  "python",
}
pack.later(function() require("nvim-treesitter").install(parsers) end)

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config.treesitter", {}),
  callback = function(ev)
    if not pcall(vim.treesitter.start, ev.buf) then return end
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

vim.g.no_plugin_maps = true
local textobjects = pack.once(
  function()
    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true },
      move = { set_jumps = true },
    })
  end
)

local select = function(obj)
  return function()
    textobjects()
    require("nvim-treesitter-textobjects.select").select_textobject(obj, "textobjects")
  end
end
local move = function(fn, obj)
  return function()
    textobjects()
    require("nvim-treesitter-textobjects.move")[fn](obj, "textobjects")
  end
end
for lhs, obj in pairs({
  af = "@function.outer",
  ["if"] = "@function.inner",
  ac = "@class.outer",
  ic = "@class.inner",
  aa = "@parameter.outer",
  ia = "@parameter.inner",
}) do
  vim.keymap.set({ "x", "o" }, lhs, select(obj), { desc = obj })
end
vim.keymap.set({ "n", "x", "o" }, "]m", move("goto_next_start", "@function.outer"), { desc = "Next function" })
vim.keymap.set({ "n", "x", "o" }, "[m", move("goto_previous_start", "@function.outer"), { desc = "Prev function" })
vim.keymap.set({ "n", "x", "o" }, "]M", move("goto_next_end", "@function.outer"), { desc = "Next function end" })
vim.keymap.set({ "n", "x", "o" }, "[M", move("goto_previous_end", "@function.outer"), { desc = "Prev function end" })
