local M = {}

function M.setup()
  local hl = vim.api.nvim_set_hl

  -- Panel backgrounds
  hl(0, "GitUIStatusBg", { bg = "#11111b" })
  hl(0, "GitUIStatusCursorLine", { bg = "#181825" })

  -- Git status colors
  hl(0, "GitUIStaged", { fg = "#a6e3a1", bold = true })
  hl(0, "GitUIModified", { fg = "#f9e2af", bold = true })
  hl(0, "GitUIUntracked", { fg = "#94e2d5" })
  hl(0, "GitUIDeleted", { fg = "#f38ba8", bold = true })
  hl(0, "GitUIRenamed", { fg = "#89b4fa" })
  hl(0, "GitUIConflict", { fg = "#fab387", bold = true })

  -- Branch and headers
  hl(0, "GitUIBranch", { fg = "#cba6f7", bold = true })
  hl(0, "GitUISectionHeader", { fg = "#7f849c", bold = true })
  hl(0, "GitUISectionCount", { fg = "#585b70" })
  hl(0, "GitUIHeader", { fg = "#cdd6f4", bold = true })

  -- File paths
  hl(0, "GitUIFilePath", { fg = "#6c7086" })
  hl(0, "GitUIFileName", { fg = "#cdd6f4" })

  -- Help footer
  hl(0, "GitUIHelpKey", { fg = "#f9e2af", bold = true })
  hl(0, "GitUIHelpText", { fg = "#585b70" })

  -- Diff
  hl(0, "GitUIDiffAdd", { bg = "#1a332a" })
  hl(0, "GitUIDiffDelete", { bg = "#331a2a" })
  hl(0, "GitUIDiffAddSign", { fg = "#a6e3a1" })
  hl(0, "GitUIDiffDelSign", { fg = "#f38ba8" })
  hl(0, "GitUIDiffHeader", { fg = "#89b4fa", bold = true })
  hl(0, "GitUIDiffFile", { fg = "#cdd6f4", bold = true })
  hl(0, "GitUIDiffHunk", { fg = "#cba6f7" })
  hl(0, "GitUIConflictMarker", { bg = "#3a2a12", fg = "#fab387", bold = true })
  hl(0, "GitUIConflictMarkerSign", { fg = "#fab387" })
  hl(0, "GitUIConflictOurs", { bg = "#1f2f2f" })
  hl(0, "GitUIConflictTheirs", { bg = "#30212f" })
  hl(0, "GitUIConflictHint", { fg = "#94e2d5" })

  -- Misc
  hl(0, "GitUIClean", { fg = "#a6adc8", italic = true })
  hl(0, "GitUISeparator", { fg = "#313244" })

  -- Scrollbar
  hl(0, "GitUIScrollTrack", { bg = "#181825" })
  hl(0, "GitUIScrollVP", { bg = "#313244" })
  hl(0, "GitUIScrollAdd", { bg = "#1a332a" })
  hl(0, "GitUIScrollDel", { bg = "#331a2a" })
  hl(0, "GitUIScrollAddVP", { bg = "#2a5540" })
  hl(0, "GitUIScrollDelVP", { bg = "#552a40" })
  hl(0, "GitUIScrollConflict", { bg = "#5a4120" })
  hl(0, "GitUIScrollConflictVP", { bg = "#8a6430" })
end

return M
