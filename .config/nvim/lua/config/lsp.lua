-- Native LSP: server definitions come from nvim-lspconfig's lsp/*.lua,
-- local overrides from after/lsp/*.lua. Rust is owned by rustaceanvim.
local M = {}

M.virtual_text = { spacing = 2, source = "if_many", prefix = "●" }

-- Appended, not prepended: toolchain-built binaries (rustup's rust-analyzer,
-- `go install`ed gopls) win over Mason copies that drift from the toolchain.
local go_bin = vim.env.GOBIN or ((vim.env.GOPATH or (vim.env.HOME .. "/go")) .. "/bin")
for _, dir in ipairs({ go_bin, vim.fn.stdpath("data") .. "/mason/bin" }) do
  if not vim.env.PATH:find(dir, 1, true) then vim.env.PATH = vim.env.PATH .. ":" .. dir end
end

local sev = vim.diagnostic.severity
vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  virtual_text = M.virtual_text,
  virtual_lines = false,
  float = { source = "if_many" },
  signs = {
    text = { [sev.ERROR] = "\u{f057}", [sev.WARN] = "\u{f071}", [sev.INFO] = "\u{f05a}", [sev.HINT] = "\u{f0eb}" },
  },
})

vim.lsp.enable({
  "gopls",
  "lua_ls",
  "ts_ls",
  "jsonls",
  "html",
  "cssls",
  "emmet_ls",
  "marksman",
  "omnisharp",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config.lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    if client:supports_method("textDocument/inlayHint") then vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf }) end
    if client:supports_method("textDocument/codeLens") then vim.lsp.codelens.enable(true, { bufnr = ev.buf }) end
    if client:supports_method("textDocument/linkedEditingRange") then
      vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
    end
  end,
})

return M
