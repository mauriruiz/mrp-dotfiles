local map = vim.keymap.set

require("gitsigns").setup({
  update_debounce = 200,
  on_attach = function(buf)
    local gs = require("gitsigns")
    local function bmap(mode, lhs, rhs, desc) map(mode, lhs, rhs, { buffer = buf, desc = desc }) end
    bmap("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
    bmap("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
    bmap({ "n", "x" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
    bmap({ "n", "x" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
    bmap("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
    bmap("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
    bmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk")
    bmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
    bmap("n", "<leader>hd", gs.diffthis, "Diff against index")
    bmap({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
  end,
})

-- Local plugin: kept in-repo, loaded on first use.
vim.opt.rtp:append(vim.fn.stdpath("config") .. "/git-ui.nvim")
local git_ui_ready = false
map("n", "<leader>gg", function()
  if not git_ui_ready then
    require("git-ui").setup({})
    git_ui_ready = true
  end
  require("git-ui").toggle()
end, { desc = "Git UI" })

map("n", "<leader>gl", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit file history" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Status" })
map("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Diff hunks" })
map("n", "<leader>gL", function() Snacks.picker.git_log_line() end, { desc = "Log for line" })
map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Open in browser" })
map(
  "n",
  "<leader>ld",
  function() Snacks.terminal("lazydocker", { win = { style = "lazygit" } }) end,
  { desc = "Lazydocker" }
)
