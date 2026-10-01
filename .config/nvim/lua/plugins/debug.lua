local M = {}

-- Rust adapters come from rustaceanvim (codelldb via Mason); Go from dap-go (delve).
local ready = false
function M.setup()
  if ready then return require("dap") end
  require("plugins").load("debug")
  require("dap-view").setup({
    auto_toggle = true,
    winbar = { default_section = "scopes", controls = { enabled = true } },
    virtual_text = { enabled = true },
  })
  require("dap-go").setup()
  for name, sign in pairs({
    DapBreakpoint = { "●", "DiagnosticError" },
    DapBreakpointCondition = { "◆", "DiagnosticError" },
    DapLogPoint = { "◆", "DiagnosticInfo" },
    DapBreakpointRejected = { "○", "DiagnosticHint" },
    DapStopped = { "▶", "DiagnosticWarn" },
  }) do
    vim.fn.sign_define(name, { text = sign[1], texthl = sign[2], numhl = sign[2] })
  end
  ready = true
  return require("dap")
end

local function dap(fn, ...)
  local args = { ... }
  return function() M.setup()[fn](unpack(args)) end
end

local map = vim.keymap.set
map("n", "<leader>db", dap("toggle_breakpoint"), { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
    if cond and cond ~= "" then M.setup().set_breakpoint(cond) end
  end)
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dc", dap("continue"), { desc = "Continue / start" })
map("n", "<leader>dC", dap("run_to_cursor"), { desc = "Run to cursor" })
map("n", "<leader>dl", dap("run_last"), { desc = "Run last" })
map("n", "<leader>di", dap("step_into"), { desc = "Step into" })
map("n", "<leader>do", dap("step_over"), { desc = "Step over" })
map("n", "<leader>dO", dap("step_out"), { desc = "Step out" })
map("n", "<leader>dt", dap("terminate"), { desc = "Terminate" })
map("n", "<leader>du", function()
  M.setup()
  require("dap-view").toggle()
end, { desc = "Toggle debug view" })
map({ "n", "x" }, "<leader>dw", function()
  M.setup()
  require("dap-view").add_expr()
end, { desc = "Watch expression" })
map("n", "<leader>dh", function()
  M.setup()
  require("dap-view").hover()
end, { desc = "Hover value" })

return M
