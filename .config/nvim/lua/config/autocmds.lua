local group = vim.api.nvim_create_augroup("config", {})
local autocmd = function(event, opts)
  vim.api.nvim_create_autocmd(event, vim.tbl_extend("force", { group = group }, opts))
end

autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Pick up edits made outside Neovim (agents, git, formatters in other panes).
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd.checktime() end
  end,
})

autocmd("VimResized", {
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd.tabnext(tab)
  end,
})

autocmd("BufReadPost", {
  callback = function(ev)
    local ignore = { gitcommit = true, gitrebase = true }
    if ignore[vim.bo[ev.buf].filetype] or vim.b[ev.buf].restored_cursor then return end
    vim.b[ev.buf].restored_cursor = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd("FileType", {
  pattern = {
    "help",
    "man",
    "qf",
    "checkhealth",
    "nvim-undotree",
    "dap-float",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Close" })
  end,
})

autocmd("BufWritePre", {
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
