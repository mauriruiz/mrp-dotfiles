local M = {}

-- Colors are derived from the active colorscheme, so the UI follows any theme.
local function get(group, attr, fallback)
  return vim.api.nvim_get_hl(0, { name = group, link = false })[attr] or fallback
end

-- Mix color `a` into `b` by `t` (0 = b, 1 = a).
local function blend(a, b, t)
  local function ch(c, s) return math.floor(c / s) % 256 end
  local r = 0
  for _, s in ipairs({ 65536, 256, 1 }) do
    r = r + math.floor(ch(a, s) * t + ch(b, s) * (1 - t) + 0.5) * s
  end
  return r
end

function M.setup()
  local hl = vim.api.nvim_set_hl

  local bg = get("Normal", "bg", 0x1d2021)
  local fg = get("Normal", "fg", 0xebdbb2)
  local green = get("DiagnosticOk", "fg", 0xb8bb26)
  local red = get("DiagnosticError", "fg", 0xfb4934)
  local yellow = get("DiagnosticWarn", "fg", 0xfabd2f)
  local cyan = get("DiagnosticHint", "fg", 0x8ec07c)
  local purple = get("Constant", "fg", 0xd3869b)
  local orange = get("Special", "fg", 0xfe8019)
  local dim = get("Comment", "fg", 0x928374)
  local dimmer = blend(fg, bg, 0.35)
  local line = get("CursorLine", "bg", blend(fg, bg, 0.1))
  local border = blend(fg, bg, 0.2)
  local filler = blend(fg, bg, 0.04)
  local tint = function(c, t) return blend(c, bg, t) end

  -- Panel backgrounds
  hl(0, "GitUIStatusBg", { bg = bg })
  hl(0, "GitUIStatusCursorLine", { bg = line })

  -- Git status colors
  hl(0, "GitUIStaged", { fg = green, bold = true })
  hl(0, "GitUIModified", { fg = yellow, bold = true })
  hl(0, "GitUIUntracked", { fg = cyan })
  hl(0, "GitUIDeleted", { fg = red, bold = true })
  hl(0, "GitUIRenamed", { fg = purple })
  hl(0, "GitUIConflict", { fg = orange, bold = true })

  -- Branch and headers
  hl(0, "GitUIBranch", { fg = purple, bold = true })
  hl(0, "GitUISectionHeader", { fg = dim, bold = true })
  hl(0, "GitUISectionCount", { fg = dimmer })
  hl(0, "GitUIHeader", { fg = fg, bold = true })

  -- File paths
  hl(0, "GitUIFilePath", { fg = dim })
  hl(0, "GitUIFileName", { fg = fg })

  -- Help footer
  hl(0, "GitUIHelpKey", { fg = yellow, bold = true })
  hl(0, "GitUIHelpText", { fg = dimmer })

  -- Diff
  hl(0, "GitUIDiffAdd", { bg = tint(green, 0.12) })
  hl(0, "GitUIDiffAddInline", { bg = tint(green, 0.25) })
  hl(0, "GitUIDiffDelete", { bg = tint(red, 0.12) })
  hl(0, "GitUIDiffDelInline", { bg = tint(red, 0.25) })
  hl(0, "GitUIDiffAddSign", { fg = green })
  hl(0, "GitUIDiffDelSign", { fg = red })
  hl(0, "GitUIDiffHeader", { fg = cyan, bold = true })
  hl(0, "GitUIDiffFile", { fg = fg, bold = true })
  hl(0, "GitUIDiffHunk", { fg = purple })
  hl(0, "GitUIDiffFiller", { bg = filler })
  hl(0, "GitUIDiffDivider", { fg = border, bg = bg })
  hl(0, "GitUIConflictMarker", { bg = tint(orange, 0.15), fg = orange, bold = true })
  hl(0, "GitUIConflictMarkerSign", { fg = orange })
  hl(0, "GitUIConflictOurs", { bg = tint(cyan, 0.12) })
  hl(0, "GitUIConflictTheirs", { bg = tint(purple, 0.12) })
  hl(0, "GitUIConflictHint", { fg = cyan })

  -- Misc
  hl(0, "GitUIClean", { fg = dim, italic = true })
  hl(0, "GitUISeparator", { fg = border })

  -- Diff filepath bar
  hl(0, "GitUIDiffBarSep", { fg = border, bg = bg })
  hl(0, "GitUIDiffBarIcon", { fg = cyan, bg = bg })
  hl(0, "GitUIDiffBarDir", { fg = dim, bg = bg })
  hl(0, "GitUIDiffBarFile", { fg = fg, bg = bg, bold = true })
  hl(0, "GitUIDiffBarHint", { fg = dimmer, bg = bg, italic = true })

  -- Commit modal
  hl(0, "GitUICommitBorder", { fg = border, bg = bg })
  hl(0, "GitUICommitNormal", { fg = fg, bg = bg })
  hl(0, "GitUICommitTitle", { fg = purple, bg = bg, bold = true })
  hl(0, "GitUICommitPrompt", { fg = yellow })
  hl(0, "GitUICommitCounter", { fg = dim })
  hl(0, "GitUICommitCounterWarn", { fg = orange })
  hl(0, "GitUICommitCounterOver", { fg = red, bold = true })

  -- Log view
  hl(0, "GitUILogGraph", { fg = dim })
  hl(0, "GitUILogHash", { fg = yellow })
  hl(0, "GitUILogSubject", { fg = fg })
  hl(0, "GitUILogAuthor", { fg = purple })
  hl(0, "GitUILogDate", { fg = dimmer, italic = true })
  hl(0, "GitUILogRefs", { fg = cyan, bold = true })
  hl(0, "GitUILogHead", { fg = green, bold = true })
  hl(0, "GitUILogModeBar", { fg = purple, bold = true })

  -- Scrollbar
  hl(0, "GitUIScrollTrack", { bg = filler })
  hl(0, "GitUIScrollVP", { bg = border })
  hl(0, "GitUIScrollAdd", { bg = tint(green, 0.2) })
  hl(0, "GitUIScrollDel", { bg = tint(red, 0.2) })
  hl(0, "GitUIScrollAddVP", { bg = tint(green, 0.4) })
  hl(0, "GitUIScrollDelVP", { bg = tint(red, 0.4) })
  hl(0, "GitUIScrollConflict", { bg = tint(orange, 0.2) })
  hl(0, "GitUIScrollConflictVP", { bg = tint(orange, 0.4) })
end

return M
