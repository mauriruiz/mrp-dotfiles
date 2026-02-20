local M = {}

local ns_diff = vim.api.nvim_create_namespace("git-ui-diff")
local ns_scrollbar = vim.api.nvim_create_namespace("git-ui-scrollbar")

local state = {
  status_buf = nil,
  status_win = nil,
  diff_buf = nil,
  diff_win = nil,
  scrollbar_buf = nil,
  scrollbar_win = nil,
  is_open = false,
  prev_win = nil,
  change_starts = {},
  change_lines_set = {}, -- line_nr -> "add" | "del"
  raw_diff_lines = {},
  display_to_hunk_idx = {},
}

function M.get_state()
  return state
end

function M.is_open()
  return state.is_open
end

local function buf_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function win_valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

function M.open(status_width)
  if state.is_open then return end
  state.prev_win = vim.api.nvim_get_current_win()

  -- Create buffers
  state.status_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.status_buf].buftype = "nofile"
  vim.bo[state.status_buf].bufhidden = "wipe"
  vim.bo[state.status_buf].swapfile = false
  vim.bo[state.status_buf].filetype = "git-ui-status"

  state.diff_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.diff_buf].buftype = "nofile"
  vim.bo[state.diff_buf].bufhidden = "wipe"
  vim.bo[state.diff_buf].swapfile = false

  state.scrollbar_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.scrollbar_buf].buftype = "nofile"
  vim.bo[state.scrollbar_buf].bufhidden = "wipe"
  vim.bo[state.scrollbar_buf].swapfile = false

  -- Open a new tab so the UI is isolated
  vim.cmd("tabnew")
  local empty_buf = vim.api.nvim_get_current_buf()

  -- Right side: diff preview
  local main_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(main_win, state.diff_buf)
  state.diff_win = main_win

  -- Delete the empty buffer tabnew created
  if vim.api.nvim_buf_is_valid(empty_buf) and empty_buf ~= state.diff_buf then
    pcall(vim.api.nvim_buf_delete, empty_buf, { force = true })
  end

  -- Left side: status panel
  vim.cmd("topleft vsplit")
  state.status_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.status_win, state.status_buf)
  vim.api.nvim_win_set_width(state.status_win, status_width)

  -- Status panel window options
  local status_opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
    cursorline = true,
    winfixwidth = true,
    foldcolumn = "0",
    spell = false,
    list = false,
    statusline = " %#GitUIBranch# Git %#Normal#",
  }
  for k, v in pairs(status_opts) do
    vim.wo[state.status_win][k] = v
  end

  -- Diff panel window options
  local diff_opts = {
    number = true,
    relativenumber = false,
    signcolumn = "yes:1",
    wrap = false,
    cursorline = false,
    spell = false,
    list = false,
    statusline = " %#GitUIDiffHeader# Diff Preview %#Normal#",
  }
  for k, v in pairs(diff_opts) do
    vim.wo[state.diff_win][k] = v
  end

  -- Right edge: scrollbar
  vim.api.nvim_set_current_win(state.diff_win)
  vim.cmd("rightbelow vsplit")
  state.scrollbar_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.scrollbar_win, state.scrollbar_buf)
  vim.api.nvim_win_set_width(state.scrollbar_win, 2)

  local sb_opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
    cursorline = false,
    winfixwidth = true,
    foldcolumn = "0",
    spell = false,
    list = false,
    statusline = " ",
  }
  for k, v in pairs(sb_opts) do
    vim.wo[state.scrollbar_win][k] = v
  end

  state.is_open = true

  -- Auto-cleanup when buffers are wiped (e.g. user closes tab manually)
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = state.status_buf,
    once = true,
    callback = function()
      state.is_open = false
      if buf_valid(state.diff_buf) then
        pcall(vim.api.nvim_buf_delete, state.diff_buf, { force = true })
      end
      if buf_valid(state.scrollbar_buf) then
        pcall(vim.api.nvim_buf_delete, state.scrollbar_buf, { force = true })
      end
      state.status_buf = nil
      state.status_win = nil
      state.diff_buf = nil
      state.diff_win = nil
      state.scrollbar_buf = nil
      state.scrollbar_win = nil
    end,
  })

  -- Focus the status panel
  vim.api.nvim_set_current_win(state.status_win)
end

function M.close()
  if not state.is_open then return end
  state.is_open = false

  if buf_valid(state.status_buf) then
    pcall(vim.api.nvim_buf_delete, state.status_buf, { force = true })
  end
  if buf_valid(state.diff_buf) then
    pcall(vim.api.nvim_buf_delete, state.diff_buf, { force = true })
  end
  if buf_valid(state.scrollbar_buf) then
    pcall(vim.api.nvim_buf_delete, state.scrollbar_buf, { force = true })
  end

  state.status_buf = nil
  state.status_win = nil
  state.diff_buf = nil
  state.diff_win = nil
  state.scrollbar_buf = nil
  state.scrollbar_win = nil
end

function M.set_status_lines(lines, highlights)
  if not buf_valid(state.status_buf) then return end
  vim.bo[state.status_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.status_buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(state.status_buf, -1, 0, -1)
  if highlights then
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(
        state.status_buf,
        -1,
        hl.group,
        hl.line,
        hl.col_start or 0,
        hl.col_end or -1
      )
    end
  end
  vim.bo[state.status_buf].modifiable = false
end

---------------------------------------------------------------------------
-- Diff rendering
---------------------------------------------------------------------------

function M.set_diff_lines(lines)
  if not buf_valid(state.diff_buf) then return end

  -- Store raw diff lines for hunk operations in panel.lua
  state.raw_diff_lines = lines
  state.display_to_hunk_idx = {}

  -- Stop any previous treesitter highlighting
  pcall(vim.treesitter.stop, state.diff_buf)

  vim.bo[state.diff_buf].modifiable = true

  -- Process raw diff lines: strip prefixes so treesitter can parse as real code
  local display = {}
  local line_types = {}
  local hunk_idx = 0
  local is_first_hunk = true

  for _, line in ipairs(lines) do
    if line:match("^diff ") or line:match("^index ") or line:match("^%-%-%- ") or line:match("^%+%+%+ ") or line:match("^new file") or line:match("^deleted file") then
      -- skip metadata headers
    elseif line:match("^@@") then
      hunk_idx = hunk_idx + 1
      if not is_first_hunk then
        table.insert(display, "")
        table.insert(line_types, "blank")
        state.display_to_hunk_idx[#display] = hunk_idx
        table.insert(display, string.rep("╌", 60))
        table.insert(line_types, "separator")
        state.display_to_hunk_idx[#display] = hunk_idx
        table.insert(display, "")
        table.insert(line_types, "blank")
        state.display_to_hunk_idx[#display] = hunk_idx
      end
      is_first_hunk = false
    elseif hunk_idx > 0 then
      local first = line:sub(1, 1)
      if first == "+" then
        table.insert(display, line:sub(2))
        table.insert(line_types, "add")
      elseif first == "-" then
        table.insert(display, line:sub(2))
        table.insert(line_types, "del")
      elseif first == " " then
        table.insert(display, line:sub(2))
        table.insert(line_types, "context")
      else
        table.insert(display, line)
        table.insert(line_types, "context")
      end
      state.display_to_hunk_idx[#display] = hunk_idx
    end
  end

  -- Fallback for non-diff content (placeholder messages)
  if #display == 0 and #lines > 0 then
    display = lines
  end

  vim.api.nvim_buf_set_lines(state.diff_buf, 0, -1, false, display)

  -- Detect language from diff header and start native treesitter highlighting
  local filepath = nil
  for _, line in ipairs(lines) do
    local match = line:match("^%+%+%+ b/(.+)$")
    if match then
      filepath = match
      break
    end
  end
  if filepath then
    local ft = vim.filetype.match({ filename = filepath })
    if ft then
      vim.bo[state.diff_buf].filetype = ft
    end
  end

  -- Clear previous diff extmarks
  vim.api.nvim_buf_clear_namespace(state.diff_buf, ns_diff, 0, -1)

  -- Track changes for scrollbar + jump navigation
  state.change_starts = {}
  state.change_lines_set = {}

  for i, lt in ipairs(line_types) do
    if lt == "add" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        line_hl_group = "GitUIDiffAdd",
        sign_text = "▎",
        sign_hl_group = "GitUIDiffAddSign",
        priority = 10,
      })
      state.change_lines_set[i] = "add"
    elseif lt == "del" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        line_hl_group = "GitUIDiffDelete",
        sign_text = "▎",
        sign_hl_group = "GitUIDiffDelSign",
        priority = 10,
      })
      state.change_lines_set[i] = "del"
    elseif lt == "separator" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        end_col = #display[i],
        hl_group = "GitUISeparator",
        priority = 100,
      })
    end

    -- Track block starts
    if lt == "add" or lt == "del" then
      local prev_lt = i > 1 and line_types[i - 1] or "context"
      if prev_lt ~= "add" and prev_lt ~= "del" then
        table.insert(state.change_starts, i)
      end
    end
  end

  vim.bo[state.diff_buf].modifiable = false

  -- Auto-scroll to first change
  if #state.change_starts > 0 and win_valid(state.diff_win) then
    pcall(vim.api.nvim_win_set_cursor, state.diff_win, { state.change_starts[1], 0 })
    pcall(vim.api.nvim_win_call, state.diff_win, function()
      vim.cmd("normal! zz")
    end)
  end

  M.update_scrollbar()
end

---------------------------------------------------------------------------
-- Scrollbar
---------------------------------------------------------------------------

function M.update_scrollbar()
  if not buf_valid(state.scrollbar_buf) or not win_valid(state.scrollbar_win) then return end
  if not buf_valid(state.diff_buf) or not win_valid(state.diff_win) then return end

  local total_lines = vim.api.nvim_buf_line_count(state.diff_buf)
  local win_height = vim.api.nvim_win_get_height(state.scrollbar_win)
  if total_lines == 0 or win_height == 0 then return end

  -- Current viewport in diff panel
  local top_line = vim.fn.line("w0", state.diff_win)
  local bot_line = vim.fn.line("w$", state.diff_win)

  -- Map each change to a scrollbar position
  local sb_changes = {} -- sb_pos -> "add" | "del"
  for line_nr, change_type in pairs(state.change_lines_set) do
    local sb_pos = math.ceil(line_nr / total_lines * win_height)
    sb_pos = math.max(1, math.min(sb_pos, win_height))
    if not sb_changes[sb_pos] then
      sb_changes[sb_pos] = change_type
    end
  end

  -- Map viewport to scrollbar positions
  local vp_start = math.ceil(top_line / total_lines * win_height)
  local vp_end = math.ceil(bot_line / total_lines * win_height)
  vp_start = math.max(1, math.min(vp_start, win_height))
  vp_end = math.max(1, math.min(vp_end, win_height))

  -- Build scrollbar
  local sb_lines = {}
  local sb_hls = {}

  for i = 1, win_height do
    table.insert(sb_lines, "  ")
    local in_vp = i >= vp_start and i <= vp_end
    local change = sb_changes[i]
    local hl
    if change == "add" then
      hl = in_vp and "GitUIScrollAddVP" or "GitUIScrollAdd"
    elseif change == "del" then
      hl = in_vp and "GitUIScrollDelVP" or "GitUIScrollDel"
    else
      hl = in_vp and "GitUIScrollVP" or "GitUIScrollTrack"
    end
    table.insert(sb_hls, { group = hl, line = i - 1 })
  end

  vim.bo[state.scrollbar_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.scrollbar_buf, 0, -1, false, sb_lines)
  vim.api.nvim_buf_clear_namespace(state.scrollbar_buf, ns_scrollbar, 0, -1)
  for _, hl in ipairs(sb_hls) do
    vim.api.nvim_buf_add_highlight(state.scrollbar_buf, ns_scrollbar, hl.group, hl.line, 0, -1)
  end
  vim.bo[state.scrollbar_buf].modifiable = false
end

---------------------------------------------------------------------------
-- Focus & navigation
---------------------------------------------------------------------------

function M.focus_status()
  if win_valid(state.status_win) then
    vim.api.nvim_set_current_win(state.status_win)
  end
end

function M.focus_diff()
  if win_valid(state.diff_win) then
    vim.api.nvim_set_current_win(state.diff_win)
  end
end

function M.next_change()
  if not win_valid(state.diff_win) or #state.change_starts == 0 then return end
  local cur = vim.api.nvim_win_get_cursor(state.diff_win)[1]
  for _, line_nr in ipairs(state.change_starts) do
    if line_nr > cur then
      vim.api.nvim_win_set_cursor(state.diff_win, { line_nr, 0 })
      vim.api.nvim_win_call(state.diff_win, function() vim.cmd("normal! zz") end)
      M.update_scrollbar()
      return
    end
  end
  vim.api.nvim_win_set_cursor(state.diff_win, { state.change_starts[1], 0 })
  vim.api.nvim_win_call(state.diff_win, function() vim.cmd("normal! zz") end)
  M.update_scrollbar()
end

function M.prev_change()
  if not win_valid(state.diff_win) or #state.change_starts == 0 then return end
  local cur = vim.api.nvim_win_get_cursor(state.diff_win)[1]
  for i = #state.change_starts, 1, -1 do
    if state.change_starts[i] < cur then
      vim.api.nvim_win_set_cursor(state.diff_win, { state.change_starts[i], 0 })
      vim.api.nvim_win_call(state.diff_win, function() vim.cmd("normal! zz") end)
      M.update_scrollbar()
      return
    end
  end
  vim.api.nvim_win_set_cursor(state.diff_win, { state.change_starts[#state.change_starts], 0 })
  vim.api.nvim_win_call(state.diff_win, function() vim.cmd("normal! zz") end)
  M.update_scrollbar()
end

return M
