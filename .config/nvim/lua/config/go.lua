local M = {}

local function gopls(buf) return vim.lsp.get_clients({ bufnr = buf, name = "gopls" })[1] end

-- Synchronous so it can run inside BufWritePre, before formatting.
function M.organize_imports(buf)
  local client = gopls(buf)
  if not client then return end
  local win = vim.fn.bufwinid(buf)
  local params = vim.lsp.util.make_range_params(win ~= -1 and win or 0, client.offset_encoding)
  params.context = { only = { "source.organizeImports" }, diagnostics = {} }
  local res = client:request_sync("textDocument/codeAction", params, 1000, buf)
  for _, action in ipairs(res and res.result or {}) do
    if not action.edit and action.data then
      local resolved = client:request_sync("codeAction/resolve", action, 1000, buf)
      action = resolved and resolved.result or action
    end
    if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
  end
end

-- Apply the gopls code action of the given kind at the cursor/selection.
function M.action(kind)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { kind }, diagnostics = {} },
    })
  end
end

-- gopls attaches a documentation link to most errors (codeDescription.href).
function M.explain_error()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, d in ipairs(vim.diagnostic.get(0, { lnum = lnum })) do
    local lsp = d.user_data and d.user_data.lsp
    local href = lsp and lsp.codeDescription and lsp.codeDescription.href
    if href then return vim.ui.open(href) end
  end
  vim.notify("No documentation link for this error")
end

function M.run() Snacks.terminal({ "go", "run", "." }, { cwd = vim.fn.expand("%:p:h"), interactive = false }) end

function M.open_mod()
  local root = vim.fs.root(0, "go.mod")
  if not root then return vim.notify("No go.mod found", vim.log.levels.WARN) end
  vim.cmd.edit(root .. "/go.mod")
end

function M.mod_tidy()
  local root = vim.fs.root(0, "go.mod")
  if not root then return vim.notify("No go.mod found", vim.log.levels.WARN) end
  vim.system({ "go", "mod", "tidy" }, { cwd = root }, function(out)
    vim.schedule(function()
      if out.code == 0 then
        vim.notify("go mod tidy: done")
        vim.cmd.checktime()
      else
        vim.notify("go mod tidy failed:\n" .. out.stderr, vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
