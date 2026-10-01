-- Seamless C-h/j/k/l across Neovim splits and tmux panes.
-- tmux reads @pane-is-vim to decide whether to forward the key (see tmux.conf).
local M = {}

local tmux_dir = { h = "L", j = "D", k = "U", l = "R" }
local tmux_edge = { h = "left", j = "bottom", k = "top", l = "right" }

function M.go(dir)
  local win = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(dir)
  if vim.env.TMUX and vim.api.nvim_get_current_win() == win then
    vim.system({ "tmux", "if-shell", "-F", "#{pane_at_" .. tmux_edge[dir] .. "}", "", "select-pane -" .. tmux_dir[dir] })
  end
end

-- From terminal mode: leave it first, or wincmd is ignored.
function M.term(dir)
  vim.cmd.stopinsert()
  vim.schedule(function() M.go(dir) end)
end

function M.setup()
  for dir in pairs(tmux_dir) do
    vim.keymap.set({ "n", "x" }, "<C-" .. dir .. ">", function() M.go(dir) end, { desc = "Go to split/pane " .. dir })
  end

  local pane = vim.env.TMUX_PANE
  if not pane then return end
  local group = vim.api.nvim_create_augroup("config.navigate", {})
  vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
    group = group,
    callback = function() vim.system({ "tmux", "set-option", "-pt", pane, "@pane-is-vim", "1" }) end,
  })
  -- Synchronous so the flag is cleared before Neovim exits or suspends.
  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = group,
    callback = function() vim.system({ "tmux", "set-option", "-put", pane, "@pane-is-vim" }):wait(500) end,
  })
end

return M
