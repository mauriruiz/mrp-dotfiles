return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = {},
    quickfile = {},
    input = {},
    notifier = {},
    terminal = {},
    words = {},
    explorer = { replace_netrw = true },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = { preset = "sidebar", preview = false, hidden = { "input" } },
          -- Keep the global keys working inside the sidebar.
          actions = {
            focus_main = function(picker) vim.api.nvim_set_current_win(picker.main) end,
            find_files = function(picker)
              vim.api.nvim_set_current_win(picker.main)
              require("telescope.builtin").find_files()
            end,
          },
          win = {
            list = { keys = { ["<c-b>"] = "close", ["<c-n>"] = "focus_main", ["<c-p>"] = "find_files" } },
          },
        },
      },
    },
    dashboard = {
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    indent = {
      indent = { char = "▏" },
      scope = { char = "▏" },
      animate = { enabled = false },
    },
  },
  keys = {
    {
      "<C-b>",
      function()
        local open = Snacks.picker.get({ source = "explorer" })[1]
        if open then open:close() else Snacks.explorer() end
      end,
      desc = "Toggle explorer",
    },
    {
      "<C-n>",
      function()
        local open = Snacks.picker.get({ source = "explorer" })[1]
        if open then open:focus("list") else Snacks.explorer() end
      end,
      desc = "Focus explorer",
    },
    { "<leader>lg", function() Snacks.lazygit() end, desc = "LazyGit" },
    { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notifications" },
  },
}
