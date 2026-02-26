local M = {}

local ns_diff = vim.api.nvim_create_namespace("git-ui-diff")
local ns_status = vim.api.nvim_create_namespace("git-ui-status")
local ns_scrollbar = vim.api.nvim_create_namespace("git-ui-scrollbar")
local ns_ts = vim.api.nvim_create_namespace("git-ui-ts")

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
  display_to_conflict_idx = {}, -- display_line_nr -> conflict_idx (1-based)
  conflict_count = 0,
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

  -- Calculate layout dimensions
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - 2 -- subtract statusline + cmdline
  local scrollbar_width = 2
  local diff_width = math.max(1, editor_width - status_width - scrollbar_width)

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

  -- Full-screen floating windows (no tabs)
  state.status_win = vim.api.nvim_open_win(state.status_buf, true, {
    relative = "editor",
    row = 0,
    col = 0,
    width = status_width,
    height = editor_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.diff_win = vim.api.nvim_open_win(state.diff_buf, false, {
    relative = "editor",
    row = 0,
    col = status_width,
    width = diff_width,
    height = editor_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.scrollbar_win = vim.api.nvim_open_win(state.scrollbar_buf, false, {
    relative = "editor",
    row = 0,
    col = status_width + diff_width,
    width = scrollbar_width,
    height = editor_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

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
    winhighlight = "Normal:GitUIStatusBg,CursorLine:GitUIStatusCursorLine",
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

  -- Scrollbar window options
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

  -- Auto-cleanup when any buffer is wiped (e.g. user :q on a panel)
  for _, buf in ipairs({ state.status_buf, state.diff_buf, state.scrollbar_buf }) do
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf,
      once = true,
      callback = function()
        vim.schedule(function()
          M.close()
        end)
      end,
    })
  end

  -- Focus the status panel
  vim.api.nvim_set_current_win(state.status_win)
end

function M.close()
  if not state.is_open then return end
  state.is_open = false

  -- Close all floating windows (bufhidden=wipe handles buffer cleanup)
  for _, win in ipairs({ state.scrollbar_win, state.diff_win, state.status_win }) do
    if win_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- Restore focus to previous window
  if state.prev_win and win_valid(state.prev_win) then
    pcall(vim.api.nvim_set_current_win, state.prev_win)
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
  vim.api.nvim_buf_clear_namespace(state.status_buf, ns_status, 0, -1)
  if highlights then
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(
        state.status_buf,
        ns_status,
        hl.group,
        hl.line,
        hl.col_start or 0,
        hl.col_end or -1
      )
    end
  end
  vim.bo[state.status_buf].modifiable = false
end

function M.set_diff_statusline(filepath)
  if not win_valid(state.diff_win) then return end
  if filepath then
    local safe = filepath:gsub("%%", "%%%%")
    vim.wo[state.diff_win].statusline = " %#GitUIDiffFile# " .. safe .. " %#Normal#"
  else
    vim.wo[state.diff_win].statusline = " %#GitUIHelpText# Diff Preview %#Normal#"
  end
end

---------------------------------------------------------------------------
-- Treesitter syntax highlighting for diff buffers
---------------------------------------------------------------------------

--- Parse valid source lines with treesitter (via a temp buffer) and apply
--- token highlights to the display buffer. `line_map` maps 1-based source
--- line indices to 1-based display line indices.
local function apply_ts_highlights(buf, source_lines, line_map, lang, display_lines)
  local tmp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, source_lines)

  local ok, parser = pcall(vim.treesitter.get_parser, tmp_buf, lang)
  if not ok or not parser then
    vim.api.nvim_buf_delete(tmp_buf, { force = true })
    return
  end

  local trees = parser:parse()
  if not trees or not trees[1] then
    vim.api.nvim_buf_delete(tmp_buf, { force = true })
    return
  end

  local ok2, query = pcall(vim.treesitter.query.get, lang, "highlights")
  if not ok2 or not query then
    vim.api.nvim_buf_delete(tmp_buf, { force = true })
    return
  end

  for id, node in query:iter_captures(trees[1]:root(), tmp_buf) do
    local hl_group = "@" .. query.captures[id] .. "." .. lang
    local sr, sc, er, ec = node:range()

    if sr == er then
      local disp_row = line_map[sr + 1]
      if disp_row then
        pcall(vim.api.nvim_buf_set_extmark, buf, ns_ts, disp_row - 1, sc, {
          end_col = ec,
          hl_group = hl_group,
          priority = 100,
        })
      end
    else
      for row = sr, er do
        local disp_row = line_map[row + 1]
        if disp_row then
          local c_start = (row == sr) and sc or 0
          local c_end = (row == er) and ec or #(display_lines[disp_row] or "")
          pcall(vim.api.nvim_buf_set_extmark, buf, ns_ts, disp_row - 1, c_start, {
            end_col = c_end,
            hl_group = hl_group,
            priority = 100,
          })
        end
      end
    end
  end

  vim.api.nvim_buf_delete(tmp_buf, { force = true })
end

---------------------------------------------------------------------------
-- Diff rendering
---------------------------------------------------------------------------

function M.set_diff_lines(lines, opts)
  opts = opts or {}
  if not buf_valid(state.diff_buf) then return end

  -- Store raw diff lines for hunk operations in panel.lua
  state.raw_diff_lines = lines
  state.display_to_hunk_idx = {}
  state.display_to_conflict_idx = {}
  state.conflict_count = 0

  -- Stop any previous treesitter highlighting
  pcall(vim.treesitter.stop, state.diff_buf)

  vim.bo[state.diff_buf].modifiable = true

  -- Process raw diff lines: strip prefixes so treesitter can parse as real code
  local display = {}
  local line_types = {}
  if opts.conflict then
    display = lines
    local hint_lines = opts.hint_lines or 0
    local block = nil -- "ours" | "theirs"
    local conflict_idx = 0
    for i, line in ipairs(display) do
      if i <= hint_lines then
        line_types[i] = "hint"
      elseif line:match("^<<<<<<<") then
        conflict_idx = conflict_idx + 1
        line_types[i] = "conflict_marker"
        block = "ours"
        state.display_to_conflict_idx[i] = conflict_idx
      elseif line:match("^=======$") then
        line_types[i] = "conflict_separator"
        block = "theirs"
        state.display_to_conflict_idx[i] = conflict_idx
      elseif line:match("^>>>>>>>") then
        line_types[i] = "conflict_marker"
        block = nil
        state.display_to_conflict_idx[i] = conflict_idx
      elseif block == "ours" then
        line_types[i] = "conflict_ours"
        state.display_to_conflict_idx[i] = conflict_idx
      elseif block == "theirs" then
        line_types[i] = "conflict_theirs"
        state.display_to_conflict_idx[i] = conflict_idx
      else
        line_types[i] = "context"
      end
    end
    state.conflict_count = conflict_idx

  else
    local hunk_idx = 0
    local is_first_hunk = true

    for _, line in ipairs(lines) do
      if line:match("^diff ")
        or line:match("^index ")
        or line:match("^%-%-%- ")
        or line:match("^%+%+%+ ")
        or line:match("^new file")
        or line:match("^deleted file")
      then
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
  end

  vim.api.nvim_buf_set_lines(state.diff_buf, 0, -1, false, display)

  -- Detect language from diff header for syntax highlighting
  local filepath = opts.filepath
  if not filepath then
    for _, line in ipairs(lines) do
      local match = line:match("^%+%+%+ b/(.+)$")
      if match then
        filepath = match
        break
      end
    end
  end

  -- Clear previous extmarks
  vim.api.nvim_buf_clear_namespace(state.diff_buf, ns_ts, 0, -1)
  vim.api.nvim_buf_clear_namespace(state.diff_buf, ns_diff, 0, -1)

  -- Syntax highlighting: set filetype for baseline vim regex syntax, then
  -- enhance with treesitter highlights parsed from valid reconstructed source.
  if filepath then
    local ft = vim.filetype.match({ filename = filepath })
    if ft then
      -- Set filetype — triggers vim regex syntax as baseline highlighting.
      -- nvim-treesitter's FileType autocmd will also auto-start treesitter,
      -- but it can't parse the invalid interleaved diff content, so we stop
      -- it and restore vim regex syntax instead.
      vim.bo[state.diff_buf].filetype = ft

      if opts.conflict then
        -- Conflict content is mostly valid — keep treesitter on the buffer
        local lang = vim.treesitter.language.get_lang(ft) or ft
        pcall(vim.treesitter.start, state.diff_buf, lang)
      else
        -- Stop treesitter (can't handle interleaved add/del lines) and
        -- re-enable vim regex syntax that treesitter.start disabled.
        pcall(vim.treesitter.stop, state.diff_buf)
        vim.bo[state.diff_buf].syntax = ft

        -- Layer richer treesitter highlights on top by parsing valid source.
        -- We reconstruct two versions: "new" (context + adds) and "old"
        -- (context + dels), parse each, then map token highlights back.
        pcall(function()
          local lang = vim.treesitter.language.get_lang(ft) or ft

          -- Build "new" version (context + additions)
          local new_lines = {}
          local new_to_display = {} -- new_line_idx -> display_line_idx
          local has_dels = false
          for i, lt in ipairs(line_types) do
            if lt == "context" or lt == "add" then
              table.insert(new_lines, display[i])
              new_to_display[#new_lines] = i
            elseif lt == "del" then
              has_dels = true
            end
          end
          if #new_lines > 0 then
            apply_ts_highlights(state.diff_buf, new_lines, new_to_display, lang, display)
          end

          -- Build "old" version (context + deletions) for deleted lines
          if has_dels then
            local old_lines = {}
            local old_to_display = {}
            for i, lt in ipairs(line_types) do
              if lt == "context" or lt == "del" then
                table.insert(old_lines, display[i])
                old_to_display[#old_lines] = i
              end
            end
            if #old_lines > 0 then
              apply_ts_highlights(state.diff_buf, old_lines, old_to_display, lang, display)
            end
          end
        end)
      end
    end
  end

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
    elseif lt == "conflict_marker" or lt == "conflict_separator" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        line_hl_group = "GitUIConflictMarker",
        sign_text = "▎",
        sign_hl_group = "GitUIConflictMarkerSign",
        priority = 12,
      })
      state.change_lines_set[i] = "conflict"
      if display[i] and display[i]:match("^<<<<<<<") then
        table.insert(state.change_starts, i)
      end
    elseif lt == "conflict_ours" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        line_hl_group = "GitUIConflictOurs",
        priority = 11,
      })
      state.change_lines_set[i] = "conflict"
    elseif lt == "conflict_theirs" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        line_hl_group = "GitUIConflictTheirs",
        priority = 11,
      })
      state.change_lines_set[i] = "conflict"
    elseif lt == "hint" then
      vim.api.nvim_buf_set_extmark(state.diff_buf, ns_diff, i - 1, 0, {
        end_col = #display[i],
        hl_group = "GitUIConflictHint",
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
  local sb_changes = {} -- sb_pos -> "add" | "del" | "conflict"
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
    elseif change == "conflict" then
      hl = in_vp and "GitUIScrollConflictVP" or "GitUIScrollConflict"
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
