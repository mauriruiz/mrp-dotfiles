local pack = require("config.pack")

local map = vim.keymap.set
local pick = Snacks.picker

local function grug()
  require("plugins").load("replace")
  return require("grug-far")
end

-- Live grep with two extras: <C-r> hands the query to grug-far for a
-- previewed project-wide replace, <C-s> re-scopes the search to a directory.
local function grep(opts)
  opts = opts or {}
  pick.grep(vim.tbl_deep_extend("force", {
    win = {
      input = {
        keys = {
          ["<c-r>"] = { "replace", mode = { "i", "n" }, nowait = true },
          ["<c-s>"] = { "rescope", mode = { "i", "n" } },
        },
      },
    },
    actions = {
      replace = function(picker)
        local search, regex, dirs = picker:filter().search, picker.opts.regex, picker.opts.dirs
        picker:close()
        grug().open({
          prefills = {
            search = search,
            flags = regex == false and "--fixed-strings" or nil,
            paths = dirs and table.concat(dirs, " ") or nil,
          },
        })
      end,
      rescope = function(picker)
        local search = picker:filter().search
        picker:close()
        vim.ui.input(
          { prompt = "Grep in: ", default = vim.fn.expand("%:.:h") .. "/", completion = "dir" },
          function(dir)
            if not dir or dir == "" then return end
            grep(vim.tbl_extend("force", opts, { dirs = { dir }, search = search }))
          end
        )
      end,
    },
  }, opts))
end

-- Find
map("n", "<C-p>", function() pick.files() end, { desc = "Files" })
map("n", "<leader>ff", function() pick.files() end, { desc = "Files" })
map("n", "<leader>fg", function() grep({ regex = false }) end, { desc = "Grep (literal)" })
map("n", "<leader>fG", function() grep() end, { desc = "Grep (regex)" })
map({ "n", "x" }, "<leader>fw", function() pick.grep_word() end, { desc = "Grep word/selection" })
map("n", "<leader>fb", function() pick.buffers() end, { desc = "Buffers" })
map("n", "<leader>fr", function() pick.recent({ filter = { cwd = true } }) end, { desc = "Recent (cwd)" })
map("n", "<leader>fd", function() pick.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>fD", function() pick.diagnostics_buffer() end, { desc = "Diagnostics (buffer)" })
map("n", "<leader>fs", function() pick.lsp_symbols() end, { desc = "Symbols" })
map("n", "<leader>fS", function() pick.lsp_workspace_symbols() end, { desc = "Symbols (workspace)" })
map("n", "<leader>fh", function() pick.help() end, { desc = "Help" })
map("n", "<leader>fk", function() pick.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>fq", function() pick.qflist() end, { desc = "Quickfix" })
map("n", "<leader>fu", function() pick.undo() end, { desc = "Undo history" })
map("n", "<leader>fn", function() Snacks.notifier.show_history() end, { desc = "Notifications" })
map("n", "<leader>fc", function() pick.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Config files" })
map("n", "<leader>f.", function() pick.resume() end, { desc = "Resume last picker" })

-- LSP navigation through the picker (overrides the builtin gr* equivalents).
map("n", "gd", function() pick.lsp_definitions() end, { desc = "Definition" })
map("n", "gD", function() pick.lsp_declarations() end, { desc = "Declaration" })
map("n", "grr", function() pick.lsp_references() end, { desc = "References" })
map("n", "gri", function() pick.lsp_implementations() end, { desc = "Implementations" })
map("n", "grt", function() pick.lsp_type_definitions() end, { desc = "Type definition" })
map("n", "gO", function() pick.lsp_symbols() end, { desc = "Document symbols" })
map("n", "]]", function() Snacks.words.jump(vim.v.count1) end, { desc = "Next reference" })
map("n", "[[", function() Snacks.words.jump(-vim.v.count1) end, { desc = "Prev reference" })

-- Explorer, buffers, terminals
local neotree = pack.once(function()
  require("plugins").load("tree")
  require("neo-tree").setup({
    close_if_last_window = true,
    popup_border_style = "",
    filesystem = {
      hijack_netrw_behavior = "disabled",
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
    },
  })
end)
local function tree(args)
  return function()
    neotree()
    vim.cmd("Neotree " .. args)
  end
end
map("n", "<C-n>", tree("filesystem reveal left"), { desc = "File tree" })
map("n", "<leader>e", tree("toggle"), { desc = "Toggle file tree" })
map("n", "<C-b>", tree("toggle"), { desc = "Toggle file tree" })

-- `nvim <dir>` opens the tree (netrw is disabled).
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if type(arg) == "string" and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      tree("filesystem reveal left dir=" .. vim.fn.fnameescape(arg))()
    end
  end,
})
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete other buffers" })
map(
  { "n", "t" },
  [[<C-\>]],
  function() Snacks.terminal.toggle(nil, { win = { position = "right", width = 0.35 } }) end,
  { desc = "Terminal" }
)
map(
  "n",
  "<leader>ac",
  function() Snacks.terminal.toggle("claude", { win = { position = "right", width = 0.4 } }) end,
  { desc = "Claude Code" }
)

-- Replace
map(
  "n",
  "<leader>rr",
  function() grug().open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
  { desc = "Replace in project" }
)
map("x", "<leader>rr", function() grug().with_visual_selection() end, { desc = "Replace selection" })
map(
  "n",
  "<leader>rf",
  function() grug().open({ prefills = { search = vim.fn.expand("<cword>"), paths = vim.fn.expand("%") } }) end,
  { desc = "Replace in file" }
)

-- Toggles
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("spell", { name = "Spell" }):map("<leader>us")
Snacks.toggle
  .new({
    name = "Diagnostic lines",
    get = function() return vim.diagnostic.config().virtual_lines ~= false end,
    set = function(on)
      vim.diagnostic.config({
        virtual_lines = on and { current_line = true } or false,
        virtual_text = not on and require("config.lsp").virtual_text or false,
      })
    end,
  })
  :map("<leader>uv")
Snacks.toggle
  .new({
    name = "Code lens",
    get = function() return vim.lsp.codelens.is_enabled() end,
    set = function(on) vim.lsp.codelens.enable(on) end,
  })
  :map("<leader>uc")

pack.later(function() require("mini.surround").setup({ mappings = { suffix_last = "", suffix_next = "" } }) end)
