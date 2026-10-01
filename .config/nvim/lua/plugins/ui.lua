local pack = require("config.pack")

local c = require("gruvbox").palette
local bar = { fg = c.gray, bg = c.dark0 }
local function bar_fg(fg, bold) return vim.tbl_extend("force", bar, { fg = fg, bold = bold }) end
local edge = { fg = c.dark2, bg = c.dark0_hard }
require("gruvbox").setup({
  contrast = "hard",
  bold = false, -- bolded function names made code look heavy
  overrides = {
    SignColumn = { link = "Normal" },
    LspInlayHint = { link = "Comment" },
    -- Bordered floats and menus share the editor background instead of a grey slab.
    NormalFloat = { link = "Normal" },
    Pmenu = { link = "Normal" },
    SnacksIndentScope = { fg = c.dark4 },
    GitSignsCurrentLineBlame = { fg = c.dark4, italic = true },
    -- Zed-like chrome: quiet gray frames, flat status bar, mode as text.
    FloatBorder = edge,
    BlinkCmpMenuBorder = edge,
    FloatTitle = { fg = c.light4, bg = c.dark0_hard },
    WinSeparator = { fg = c.dark1 },
    StatusLine = bar,
    MiniStatuslineModeNormal = bar_fg(c.bright_blue, true),
    MiniStatuslineModeInsert = bar_fg(c.bright_green, true),
    MiniStatuslineModeVisual = bar_fg(c.bright_purple, true),
    MiniStatuslineModeReplace = bar_fg(c.bright_red, true),
    MiniStatuslineModeCommand = bar_fg(c.bright_orange, true),
    MiniStatuslineModeOther = bar_fg(c.bright_aqua, true),
    MiniStatuslineDevinfo = bar,
    MiniStatuslineFileinfo = bar,
    MiniStatuslineFilename = bar_fg(c.light3),
    MiniStatuslineInactive = bar_fg(c.dark4),
  },
})
vim.cmd.colorscheme("gruvbox")

require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("snacks").setup({
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, style = "compact", timeout = 3000 },
  words = { enabled = true },
  indent = {
    enabled = true,
    indent = { char = "▏" },
    scope = { char = "▏" },
    animate = { enabled = false },
  },
  picker = {
    ui_select = true,
    sources = {
      files = { layout = { preset = "vscode" } },
      buffers = { layout = { preset = "vscode" } },
      recent = { layout = { preset = "vscode" } },
      keymaps = { layout = { preset = "vscode" } },
      help = { layout = { preset = "vscode" } },
    },
    win = {
      input = {
        keys = {
          -- AeroSpace owns alt-h/alt-f system-wide.
          ["<a-.>"] = { "toggle_hidden", mode = { "i", "n" } },
        },
      },
    },
  },
  lazygit = { configure = true },
  terminal = {
    win = {
      keys = {
        nav_h = { "<C-h>", function() require("config.navigate").term("h") end, mode = "t", desc = "Go left" },
        nav_j = { "<C-j>", function() require("config.navigate").term("j") end, mode = "t", desc = "Go down" },
        nav_k = { "<C-k>", function() require("config.navigate").term("k") end, mode = "t", desc = "Go up" },
        nav_l = { "<C-l>", function() require("config.navigate").term("l") end, mode = "t", desc = "Go right" },
      },
    },
  },
})

require("mini.statusline").setup({
  use_icons = true,
  set_vim_settings = false,
  content = {
    active = function()
      local S = MiniStatusline
      local mode, mode_hl = S.section_mode({ trunc_width = 120 })
      local git = S.section_git({ trunc_width = 40 })
      local diff = S.section_diff({ trunc_width = 75 })
      local diagnostics = S.section_diagnostics({ trunc_width = 75 })
      local lsp = S.is_truncated(100) and ""
        or table.concat(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 })), " ")
      local filename = S.section_filename({ trunc_width = 140 })
      local progress = vim.ui.progress_status()
      local search = S.section_searchcount({ trunc_width = 75 })
      local location = "%l:%v"
      return S.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = "MiniStatuslineFilename", strings = { progress } },
        { hl = "MiniStatuslineDevinfo", strings = { diagnostics, lsp } },
        { hl = mode_hl, strings = { search, location } },
      })
    end,
  },
})

pack.later(function()
  local wk = require("which-key")
  wk.setup({ preset = "helix", delay = 300 })
  wk.add({
    { "<leader>a", group = "ai" },
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>C", group = "crates" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "hunk" },
    { "<leader>l", group = "tools" },
    { "<leader>p", group = "plugins" },
    { "<leader>q", group = "quit" },
    { "<leader>r", group = "replace" },
    { "<leader>t", group = "test" },
    { "<leader>u", group = "toggle" },
    { "<localleader>", group = "language" },
  })
end)
