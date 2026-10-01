-- Thin helpers over the builtin plugin manager (:h vim.pack).
local M = {}

-- Run fn once, on the first matching event.
function M.on(events, fn, pattern)
  vim.api.nvim_create_autocmd(events, { pattern = pattern, once = true, callback = function(ev) fn(ev) end })
end

-- Run fn once startup has finished.
function M.later(fn)
  if vim.v.vim_did_enter == 1 then return vim.schedule(fn) end
  M.on("VimEnter", function() vim.schedule(fn) end)
end

-- Wrap a setup function so it runs once, on first call; returns its result after.
function M.once(fn)
  local done, result = false, nil
  return function()
    if not done then
      result = fn()
      done = true
    end
    return result
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("config.pack", {}),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

vim.api.nvim_create_user_command(
  "PackUpdate",
  function(o) vim.pack.update(#o.fargs > 0 and o.fargs or nil) end,
  { nargs = "*", desc = "Update plugins (review, then :w to apply)" }
)

vim.api.nvim_create_user_command("PackClean", function()
  local declared = require("plugins").names()
  local stale = vim
    .iter(vim.pack.get())
    :map(function(p) return p.spec.name end)
    :filter(function(name) return not declared[name] end)
    :totable()
  if #stale == 0 then return vim.notify("No stale plugins") end
  vim.pack.del(stale, { force = true })
  vim.notify("Removed: " .. table.concat(stale, ", "))
end, { desc = "Delete plugins no longer declared in lua/plugins/init.lua" })

return M
