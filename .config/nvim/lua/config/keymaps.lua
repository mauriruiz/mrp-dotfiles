-- Global keymaps; plugin and LSP keys live next to their config in lua/plugins/.
-- Neovim defaults cover a lot (see :h default-mappings): [b ]b [q ]q [d ]d,
-- grn gra grr gri grt grx gO, gcc, K, <C-w>d, visual an/in selection.
local map = vim.keymap.set

map("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>")
map("x", "<", "<gv")
map("x", ">", ">gv")

local function jump_severity(count, severity)
  return function() vim.diagnostic.jump({ count = count, severity = severity }) end
end
map("n", "]e", jump_severity(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
map("n", "[e", jump_severity(-1, vim.diagnostic.severity.ERROR), { desc = "Prev error" })

map("n", "<leader>qq", "<Cmd>qa<CR>", { desc = "Quit all" })
map("n", "<leader>qr", "<Cmd>restart<CR>", { desc = "Restart Neovim" })
map("n", "<leader>pu", "<Cmd>PackUpdate<CR>", { desc = "Update plugins" })
map("n", "<leader>pc", "<Cmd>PackClean<CR>", { desc = "Remove stale plugins" })
map("n", "<leader>pm", "<Cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>pt", "<Cmd>TSUpdate<CR>", { desc = "Update treesitter parsers" })

require("config.navigate").setup()
