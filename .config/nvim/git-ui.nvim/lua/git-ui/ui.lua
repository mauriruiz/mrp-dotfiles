local M = {}

local ns_diff = vim.api.nvim_create_namespace("git-ui-diff")
local ns_status = vim.api.nvim_create_namespace("git-ui-status")
local ns_scrollbar = vim.api.nvim_create_namespace("git-ui-scrollbar")
local ns_ts = vim.api.nvim_create_namespace("git-ui-ts")

local state = {
  status_buf = nil,
  status_win = nil,
  help_buf = nil,
  help_win = nil,
  diff_buf = nil,
  diff_win = nil,
  diffbar_buf = nil,
  diffbar_win = nil,
  scrollbar_buf = nil,
  scrollbar_win = nil,
  is_open = false,
  prev_win = nil,
  prev_laststatus = nil,
  change_starts = {},
  change_lines_set = {}, -- line_nr -> "add" | "del"
  raw_diff_lines = {},
  display_to_hunk_idx = {},
  display_to_conflict_idx = {}, -- display_line_nr -> conflict_idx (1-based)
  conflict_count = 0,
  help_height = 12, -- lines reserved for the fixed help footer
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

  -- Hide background statusline so "[No Name]" doesn't bleed through
  state.prev_laststatus = vim.o.laststatus
  vim.o.laststatus = 0

  -- Calculate layout dimensions — cover full editor (only cmdline below)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - 1
  local scrollbar_width = 2
  local diff_width = math.max(1, editor_width - status_width - scrollbar_width)
  local diffbar_height = 1
  local diff_content_height = editor_height - diffbar_height

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
  vim.bo[state.diff_buf].filetype = "git-ui-diff"

  state.scrollbar_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.scrollbar_buf].buftype = "nofile"
  vim.bo[state.scrollbar_buf].bufhidden = "wipe"
  vim.bo[state.scrollbar_buf].swapfile = false

  -- Help footer buffer (fixed, non-scrollable)
  state.help_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.help_buf].buftype = "nofile"
  vim.bo[state.help_buf].bufhidden = "wipe"
  vim.bo[state.help_buf].swapfile = false

  -- Diff filepath bar buffer
  state.diffbar_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.diffbar_buf].buftype = "nofile"
  vim.bo[state.diffbar_buf].bufhidden = "wipe"
  vim.bo[state.diffbar_buf].swapfile = false

  local status_height = editor_height - state.help_height

  -- Full-screen floating windows
  state.status_win = vim.api.nvim_open_win(state.status_buf, true, {
    relative = "editor",
    row = 0,
    col = 0,
    width = status_width,
    height = status_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.help_win = vim.api.nvim_open_win(state.help_buf, false, {
    relative = "editor",
    row = status_height,
    col = 0,
    width = status_width,
    height = state.help_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.diff_win = vim.api.nvim_open_win(state.diff_buf, false, {
    relative = "editor",
    row = 0,
    col = status_width,
    width = diff_width,
    height = diff_content_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.diffbar_win = vim.api.nvim_open_win(state.diffbar_buf, false, {
    relative = "editor",
    row = diff_content_height,
    col = status_width,
    width = diff_width + scrollbar_width,
    height = diffbar_height,
    style = "minimal",
    border = "none",
    zindex = 40,
  })

  state.scrollbar_win = vim.api.nvim_open_win(state.scrollbar_buf, false, {
    relative = "editor",
    row = 0,
    col = status_width + diff_width,
    width = scrollbar_width,
    height = diff_content_height,
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
  }
  for k, v in pairs(diff_opts) do
    vim.wo[state.diff_win][k] = v
  end

  -- Diff filepath bar window options
  local diffbar_opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
    cursorline = false,
    winfixheight = true,
    foldcolumn = "0",
    spell = false,
    list = false,
    winhighlight = "Normal:GitUIStatusBg",
  }
  for k, v in pairs(diffbar_opts) do
    vim.wo[state.diffbar_win][k] = v
  end

  -- Help footer window options
  local help_opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
    cursorline = false,
    winfixwidth = true,
    winfixheight = true,
    foldcolumn = "0",
    spell = false,
    list = false,
    winhighlight = "Normal:GitUIStatusBg",
  }
  for k, v in pairs(help_opts) do
    vim.wo[state.help_win][k] = v
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
  }
  for k, v in pairs(sb_opts) do
    vim.wo[state.scrollbar_win][k] = v
  end

  state.is_open = true

  -- Auto-cleanup when any buffer is wiped (e.g. user :q on a panel)
  for _, buf in ipairs({ state.status_buf, state.help_buf, state.diff_buf, state.diffbar_buf, state.scrollbar_buf }) do
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

  -- Restore background statusline
  if state.prev_laststatus then
    vim.o.laststatus = state.prev_laststatus
    state.prev_laststatus = nil
  end

  -- Close all floating windows (bufhidden=wipe handles buffer cleanup)
  for _, win in ipairs({ state.scrollbar_win, state.diffbar_win, state.diff_win, state.help_win, state.status_win }) do
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
  state.help_buf = nil
  state.help_win = nil
  state.diff_buf = nil
  state.diff_win = nil
  state.diffbar_buf = nil
  state.diffbar_win = nil
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

local ns_help = vim.api.nvim_create_namespace("git-ui-help")

function M.set_help_lines(lines, highlights)
  if not buf_valid(state.help_buf) then return end
  vim.bo[state.help_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.help_buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(state.help_buf, ns_help, 0, -1)
  if highlights then
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(
        state.help_buf,
        ns_help,
        hl.group,
        hl.line,
        hl.col_start or 0,
        hl.col_end or -1
      )
    end
  end
  vim.bo[state.help_buf].modifiable = false
end

local ns_diffbar = vim.api.nvim_create_namespace("git-ui-diffbar")

function M.set_diff_statusline(filepath)
  if not buf_valid(state.diffbar_buf) then return end
  vim.bo[state.diffbar_buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(state.diffbar_buf, ns_diffbar, 0, -1)

  if filepath then
    -- Split into dir/ and filename
    local dir, fname = filepath:match("^(.+/)([^/]+)$")
    if not dir then fname = filepath end

    local sep = "─"
    local icon = "  "
    local text = sep .. icon
    local hls = {}

    -- separator tick
    table.insert(hls, { "GitUIDiffBarSep", 0, 0, #sep })
    -- icon
    table.insert(hls, { "GitUIDiffBarIcon", 0, #sep, #sep + #icon })

    if dir then
      text = text .. dir .. fname
      local dir_start = #sep + #icon
      table.insert(hls, { "GitUIDiffBarDir", 0, dir_start, dir_start + #dir })
      table.insert(hls, { "GitUIDiffBarFile", 0, dir_start + #dir, dir_start + #dir + #fname })
    else
      text = text .. fname
      local fname_start = #sep + #icon
      table.insert(hls, { "GitUIDiffBarFile", 0, fname_start, fname_start + #fname })
    end

    vim.api.nvim_buf_set_lines(state.diffbar_buf, 0, -1, false, { text })
    for _, h in ipairs(hls) do
      vim.api.nvim_buf_add_highlight(state.diffbar_buf, ns_diffbar, h[1], h[2], h[3], h[4])
    end
  else
    local text = "─  Diff Preview"
    vim.api.nvim_buf_set_lines(state.diffbar_buf, 0, -1, false, { text })
    vim.api.nvim_buf_add_highlight(state.diffbar_buf, ns_diffbar, "GitUIDiffBarSep", 0, 0, 3)
    vim.api.nvim_buf_add_highlight(state.diffbar_buf, ns_diffbar, "GitUIDiffBarHint", 0, 3, -1)
  end

  vim.bo[state.diffbar_buf].modifiable = false
end

function M.resize_status(delta)
  if not state.is_open then return end
  local cfg = require("git-ui.config")
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - 1
  local scrollbar_width = 2
  local diffbar_height = 1
  local diff_content_height = editor_height - diffbar_height
  local min_w = 20
  local max_w = math.floor(editor_width * 0.6)
  local cur_w = cfg.options.layout.status_width
  local new_w = math.max(min_w, math.min(max_w, cur_w + delta))
  if new_w == cur_w then return end
  cfg.options.layout.status_width = new_w
  local diff_w = math.max(1, editor_width - new_w - scrollbar_width)
  local status_height = editor_height - state.help_height
  if win_valid(state.status_win) then
    pcall(vim.api.nvim_win_set_config, state.status_win, {
      relative = "editor", row = 0, col = 0, width = new_w, height = status_height,
    })
  end
  if win_valid(state.help_win) then
    pcall(vim.api.nvim_win_set_config, state.help_win, {
      relative = "editor", row = status_height, col = 0, width = new_w, height = state.help_height,
    })
  end
  if win_valid(state.diff_win) then
    pcall(vim.api.nvim_win_set_config, state.diff_win, {
      relative = "editor", row = 0, col = new_w, width = diff_w, height = diff_content_height,
    })
  end
  if win_valid(state.diffbar_win) then
    pcall(vim.api.nvim_win_set_config, state.diffbar_win, {
      relative = "editor", row = diff_content_height, col = new_w, width = diff_w + scrollbar_width, height = diffbar_height,
    })
  end
  if win_valid(state.scrollbar_win) then
    pcall(vim.api.nvim_win_set_config, state.scrollbar_win, {
      relative = "editor", row = 0, col = new_w + diff_w, width = scrollbar_width, height = diff_content_height,
    })
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

  -- Syntax highlighting: use vim.bo.syntax (not filetype) for baseline vim
  -- regex syntax so the buffer filetype stays as git-ui-diff for lualine.
  -- Enhance with treesitter highlights parsed from valid reconstructed source.
  if filepath then
    local ft = vim.filetype.match({ filename = filepath })
    if ft then
      -- Stop any previous treesitter before changing syntax
      pcall(vim.treesitter.stop, state.diff_buf)

      if opts.conflict then
        -- Conflict content is mostly valid — use treesitter directly
        vim.bo[state.diff_buf].syntax = ft
        local lang = vim.treesitter.language.get_lang(ft) or ft
        pcall(vim.treesitter.start, state.diff_buf, lang)
      else
        -- Set vim regex syntax as baseline (filetype stays git-ui-diff)
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
