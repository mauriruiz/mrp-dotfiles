local pack = require("config.pack")
local plugins = require("plugins")

-- Completion ------------------------------------------------------------------
pack.on(
  "InsertEnter",
  function()
    require("blink.cmp").setup({
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      completion = {
        menu = { draw = { treesitter = { "lsp" } } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
      cmdline = { enabled = false },
    })
  end
)

-- Formatting --------------------------------------------------------------------
-- Go and Rust always format on save (gofmt/rustfmt are canonical). Other
-- formatters only run when the project opts in with its own config file.
local lsp_formatted = { go = true, rust = true }

local conform = pack.once(function()
  plugins.load("format")
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      cs = { "csharpier" },
    },
    formatters = {
      stylua = { require_cwd = true },
      prettier = { require_cwd = true },
      csharpier = { require_cwd = true },
    },
  })
  return require("conform")
end)

local function format(buf, on_save)
  if vim.bo[buf].filetype == "go" then require("config.go").organize_imports(buf) end
  local c = conform()
  if on_save and not lsp_formatted[vim.bo[buf].filetype] and #c.list_formatters(buf) == 0 then return end
  c.format({ bufnr = buf, timeout_ms = 1500, lsp_format = "fallback" })
end

vim.g.autoformat = true
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("config.format", {}),
  callback = function(ev)
    if vim.g.autoformat and vim.b[ev.buf].autoformat ~= false then format(ev.buf, true) end
  end,
})
vim.keymap.set(
  { "n", "x" },
  "<leader>cf",
  function() format(vim.api.nvim_get_current_buf(), false) end,
  { desc = "Format" }
)
Snacks.toggle
  .new({
    name = "Format on save",
    get = function() return vim.g.autoformat end,
    set = function(on) vim.g.autoformat = on end,
  })
  :map("<leader>uf")

-- Linting -------------------------------------------------------------------------
-- golangci-lint only where the repo defines its rules; gopls already runs the
-- staticcheck suite as you type, so a config-less run would just duplicate it.
local golangci_configs = { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" }
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("config.lint", {}),
  pattern = "*.go",
  callback = function(ev)
    if not vim.fs.root(ev.buf, golangci_configs) then return end
    plugins.load("lint")
    require("lint").try_lint("golangcilint")
  end,
})

-- Tooling ---------------------------------------------------------------------------
-- Installed only when missing from PATH, so toolchain-managed copies win.
local tools = {
  gopls = "gopls",
  ["golangci-lint"] = "golangci-lint",
  gotestsum = "gotestsum",
  delve = "dlv",
  codelldb = "codelldb",
  ["lua-language-server"] = "lua-language-server",
  stylua = "stylua",
}

local mason = pack.once(function()
  plugins.load("mason")
  require("mason").setup({ PATH = "skip" })
end)
vim.api.nvim_create_user_command("Mason", function()
  mason()
  vim.cmd("Mason")
end, { desc = "Open Mason" })

pack.later(function()
  local missing = vim.tbl_filter(function(pkg) return vim.fn.executable(tools[pkg]) == 0 end, vim.tbl_keys(tools))
  if #missing == 0 then return end
  mason()
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(missing) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() and not pkg:is_installing() then
        vim.notify("Mason: installing " .. name)
        pkg:install()
      end
    end
  end)
end)
