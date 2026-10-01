local pack = require("config.pack")

local neotest = pack.once(function()
  require("plugins").load("test")
  require("neotest").setup({
    adapters = {
      require("neotest-golang")({
        runner = vim.fn.executable("gotestsum") == 1 and "gotestsum" or "go",
      }),
      require("rustaceanvim.neotest"),
    },
    -- Project-wide discovery parses every test file up front; too slow for
    -- large monorepos. Tests in open files are still found and runnable.
    discovery = { enabled = false },
    status = { virtual_text = true },
    output = { open_on_run = false },
  })
  return require("neotest")
end)

local function run(target)
  return function() neotest().run.run(target and target()) end
end

local map = vim.keymap.set
map("n", "<leader>tt", run(), { desc = "Run nearest" })
map("n", "<leader>tf", run(function() return vim.fn.expand("%:p") end), { desc = "Run file" })
map("n", "<leader>tp", run(function() return vim.fn.expand("%:p:h") end), { desc = "Run package/dir" })
map("n", "<leader>ta", run(function() return vim.uv.cwd() end), { desc = "Run all" })
map("n", "<leader>tl", function() neotest().run.run_last() end, { desc = "Run last" })
map("n", "<leader>td", function()
  require("plugins.debug").setup()
  neotest().run.run({ strategy = "dap" })
end, { desc = "Debug nearest" })
map("n", "<leader>tS", function() neotest().run.stop() end, { desc = "Stop" })
map("n", "<leader>tw", function() neotest().watch.toggle(vim.fn.expand("%:p")) end, { desc = "Watch file" })
map("n", "<leader>ts", function() neotest().summary.toggle() end, { desc = "Summary" })
map("n", "<leader>to", function() neotest().output.open({ enter = true, auto_close = true }) end, { desc = "Output" })
map("n", "<leader>tO", function() neotest().output_panel.toggle() end, { desc = "Output panel" })
