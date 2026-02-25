local M = {}

local git = require("git-ui.git")
local ui = require("git-ui.ui")
local config = require("git-ui.config")

local state = {
  files = { conflicted = {}, staged = {}, changed = {}, untracked = {} },
  branch = { name = "", ahead = 0, behind = 0 },
  sections = {
    conflicted = { collapsed = false },
    staged = { collapsed = false },
    changed = { collapsed = false },
    untracked = { collapsed = false },
  },
  line_map = {},
  loading = false,
  conflict_history = {}, -- { [path] = { undo = {lines, ...}, redo = {lines, ...} } }
}

function M.get_state()
  return state
end

local function get_status_icon(status)
  local icons = config.options.icons
  local map = {
    UU = icons.conflict,
    AA = icons.conflict,
    DD = icons.conflict,
    AU = icons.conflict,
    UA = icons.conflict,
    DU = icons.conflict,
    UD = icons.conflict,
    M = icons.modified,
    A = icons.added,
    D = icons.deleted,
    R = icons.renamed,
    ["?"] = icons.untracked,
  }
  return map[status] or status
end

local function get_status_hl(status, section)
  if section == "conflicted" then return "GitUIConflict" end
  if section == "staged" then return "GitUIStaged" end
  local map = {
    M = "GitUIModified",
    D = "GitUIDeleted",
    A = "GitUIStaged",
    R = "GitUIRenamed",
    ["?"] = "GitUIUntracked",
  }
  return map[status] or "Normal"
end

--- Render the status panel contents.
function M.render()
  local lines = {}
  local highlights = {}
  local line_map = {}
  local icons = config.options.icons
  local width = config.options.layout.status_width

  -- Top padding
  table.insert(lines, "")
  line_map[#lines] = { type = "blank" }

  -- Branch header
  local branch = state.branch
  local branch_line = string.format("  %s %s", icons.branch, branch.name)
  if branch.ahead > 0 or branch.behind > 0 then
    branch_line = branch_line .. string.format("  ↑%d ↓%d", branch.ahead, branch.behind)
  end
  table.insert(lines, branch_line)
  table.insert(highlights, { group = "GitUIBranch", line = #lines - 1 })
  line_map[#lines] = { type = "header" }

  table.insert(lines, "")
  line_map[#lines] = { type = "blank" }

  local total_files = #state.files.conflicted + #state.files.staged + #state.files.changed + #state.files.untracked

  if total_files == 0 then
    table.insert(lines, "  Working tree clean")
    table.insert(highlights, { group = "GitUIClean", line = #lines - 1 })
    line_map[#lines] = { type = "info" }
    table.insert(lines, "")
    line_map[#lines] = { type = "blank" }
  else
    local section_order = { "conflicted", "staged", "changed", "untracked" }
    local section_labels = {
      conflicted = "CONFLICTS",
      staged = "STAGED",
      changed = "CHANGES",
      untracked = "UNTRACKED",
    }

    for _, section in ipairs(section_order) do
      local files = state.files[section]
      if #files > 0 then
        local sec = state.sections[section]
        local icon = sec.collapsed and icons.section_closed or icons.section_open
        local label = section_labels[section]
        local count_str = tostring(#files)

        -- "  ▼ STAGED                         3"
        local prefix = string.format("  %s %s", icon, label)
        local padding = math.max(1, width - #prefix - #count_str - 1)
        local header_line = prefix .. string.rep(" ", padding) .. count_str

        table.insert(lines, header_line)
        line_map[#lines] = { type = "section", section = section }
        table.insert(highlights, {
          group = "GitUISectionHeader",
          line = #lines - 1,
          col_start = 0,
          col_end = #prefix,
        })
        table.insert(highlights, {
          group = "GitUISectionCount",
          line = #lines - 1,
          col_start = #header_line - #count_str,
          col_end = #header_line,
        })

        if not sec.collapsed then
          for i, file in ipairs(files) do
            local si
            if section == "staged" then
              si = icons.staged
            elseif section == "conflicted" then
              si = icons.conflict
            else
              si = get_status_icon(file.status)
            end

            -- Split path: dim directory, bright filename
            local dir, fname = file.path:match("^(.+/)([^/]+)$")
            if not dir then fname = file.path end

            local detail = ""
            if section == "conflicted" then
              detail = string.format("[%s] ", file.status)
            end

            local file_line
            if dir then
              file_line = string.format("    %s %s%s%s", si, detail, dir, fname)
            else
              file_line = string.format("    %s %s%s", si, detail, fname)
            end

            table.insert(lines, file_line)
            line_map[#lines] = { type = "file", section = section, index = i, file = file }

            -- Icon highlight
            local icon_start = 4
            local icon_end = icon_start + #si
            table.insert(highlights, {
              group = get_status_hl(file.status, section),
              line = #lines - 1,
              col_start = icon_start,
              col_end = icon_end,
            })

            local detail_start = icon_end + 1
            local path_start = detail_start + #detail
            if #detail > 0 then
              table.insert(highlights, {
                group = "GitUIConflict",
                line = #lines - 1,
                col_start = detail_start,
                col_end = path_start,
              })
            end

            -- Path: dim directory, bright filename
            if dir then
              table.insert(highlights, {
                group = "GitUIFilePath",
                line = #lines - 1,
                col_start = path_start,
                col_end = path_start + #dir,
              })
              table.insert(highlights, {
                group = "GitUIFileName",
                line = #lines - 1,
                col_start = path_start + #dir,
                col_end = -1,
              })
            else
              table.insert(highlights, {
                group = "GitUIFileName",
                line = #lines - 1,
                col_start = path_start,
                col_end = -1,
              })
            end
          end
        end

        table.insert(lines, "")
        line_map[#lines] = { type = "blank" }
      end
    end
  end

  -- Separator
  table.insert(lines, "  " .. string.rep("─", width - 4))
  table.insert(highlights, { group = "GitUISeparator", line = #lines - 1 })
  line_map[#lines] = { type = "separator" }

  -- Help footer with key highlighting
  local help_rows = {
    { { "s", "stage" },   { "u", "unstage" },   { "d", "discard" } },
    { { "o", "ours" },    { "i", "incoming" },  { "B", "both" } },
    { { "m", "resolved" }, { "u", "undo" },      { "C-r", "redo" } },
    { { "hs", "hunk+" },  { "hu", "hunk-" } },
    { { "c", "commit" },  { "S", "stage all" }, { "U", "unstage all" } },
    { { "P", "push" },    { "L", "pull" },      { "b", "branch" } },
    { { "n", "new" },     { "r", "refresh" },   { "Tab", "diff" } },
    { { "]c", "next" },   { "[c", "prev" },     { "q/Esc", "close" } },
  }

  local cell_w = math.floor((width - 3) / 3)
  for _, row in ipairs(help_rows) do
    local line_str = "   "
    local key_ranges = {}
    local desc_ranges = {}
    local col = 3

    for _, item in ipairs(row) do
      local key, desc = item[1], item[2]
      local cell = key .. " " .. desc
      local pad = math.max(0, cell_w - #cell)
      line_str = line_str .. cell .. string.rep(" ", pad)

      table.insert(key_ranges, { s = col, e = col + #key })
      table.insert(desc_ranges, { s = col + #key + 1, e = col + #key + 1 + #desc })
      col = col + cell_w
    end

    table.insert(lines, line_str)
    line_map[#lines] = { type = "help" }

    for _, kr in ipairs(key_ranges) do
      table.insert(highlights, {
        group = "GitUIHelpKey",
        line = #lines - 1,
        col_start = kr.s,
        col_end = kr.e,
      })
    end
    for _, dr in ipairs(desc_ranges) do
      table.insert(highlights, {
        group = "GitUIHelpText",
        line = #lines - 1,
        col_start = dr.s,
        col_end = dr.e,
      })
    end
  end

  state.line_map = line_map
  ui.set_status_lines(lines, highlights)
end

--- Move cursor to the first file line after render.
local function cursor_to_first_file()
  local ui_state = ui.get_state()
  if not ui_state.status_win or not vim.api.nvim_win_is_valid(ui_state.status_win) then return end
  if not ui_state.status_buf or not vim.api.nvim_buf_is_valid(ui_state.status_buf) then return end
  local total = vim.api.nvim_buf_line_count(ui_state.status_buf)
  for line_nr = 1, total do
    if state.line_map[line_nr] and state.line_map[line_nr].type == "file" then
      pcall(vim.api.nvim_win_set_cursor, ui_state.status_win, { line_nr, 0 })
      return
    end
  end
end

--- Refresh git status and branch info, then re-render.
function M.refresh(callback)
  if state.loading then return end
  state.loading = true

  local done = 0
  local total = 2

  local function check()
    done = done + 1
    if done >= total then
      state.loading = false
      M.render()
      M.update_diff_for_cursor()
      if callback then callback() end
    end
  end

  git.status(function(files)
    state.files = files
    check()
  end)

  git.branch_info(function(info)
    state.branch = info
    check()
  end)
end

--- Get the line_map item at the current cursor position.
function M.get_item_at_cursor()
  local ui_state = ui.get_state()
  if not ui_state.status_win or not vim.api.nvim_win_is_valid(ui_state.status_win) then
    return nil
  end
  local cursor = vim.api.nvim_win_get_cursor(ui_state.status_win)
  return state.line_map[cursor[1]]
end

--- Update the diff preview panel based on the currently selected file.
function M.update_diff_for_cursor()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then
    ui.set_diff_lines({ "", "  Select a file to preview its diff" })
    ui.set_diff_statusline(nil)
    return
  end

  local file = item.file
  local staged = item.section == "staged"

  if item.section == "conflicted" then
    ui.set_diff_statusline(file.path .. " [CONFLICT]")
    local km = config.options.keymaps
    local hint = string.format(
      "    [%s] ours   [%s] incoming   [%s] both   [%s] resolved",
      km.resolve_ours,
      km.resolve_theirs,
      km.resolve_both,
      km.mark_resolved
    )

    git.read_file(file.actual_path, function(ok, lines, err)
      if not ok then
        ui.set_diff_lines({ "", "  Failed to read file: " .. err })
        return
      end

      local preview = {
        "  Tab into diff, navigate to a conflict, press o/i/B per block",
        hint,
        "",
      }
      if #lines == 0 then
        table.insert(preview, "  File is empty")
      else
        vim.list_extend(preview, lines)
      end
      ui.set_diff_lines(preview, {
        conflict = true,
        filepath = file.actual_path,
        hint_lines = 3,
      })
    end)
    return
  end

  ui.set_diff_statusline(file.path)

  local function show_diff(diff_text)
    if not diff_text or diff_text == "" then
      ui.set_diff_lines({ "", "  No changes to display" })
      return
    end
    local lines = vim.split(diff_text, "\n")
    ui.set_diff_lines(lines)
  end

  if item.section == "untracked" then
    git.diff_untracked(file.actual_path, show_diff)
  else
    git.diff(file.actual_path, staged, show_diff)
  end
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------

function M.stage_file()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then return end
  if item.section == "staged" then return end
  git.stage(item.file.actual_path, function(ok, err)
    if ok then
      M.refresh()
    else
      vim.notify("Stage failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.unstage_file()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then return end
  if item.section ~= "staged" then return end
  git.unstage(item.file.actual_path, function(ok, err)
    if ok then
      M.refresh()
    else
      vim.notify("Unstage failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.discard_file()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then return end

  if item.section == "staged" then
    vim.notify("Unstage file before discarding changes", vim.log.levels.WARN)
    return
  end
  if item.section == "conflicted" then
    vim.notify("Use conflict resolve actions (o/i/B/m) for conflicted files", vim.log.levels.WARN)
    return
  end

  local path = item.file.actual_path
  local prompt
  if item.section == "untracked" then
    prompt = "Delete untracked file '" .. path .. "'?"
  else
    prompt = "Discard changes in '" .. path .. "'?"
  end

  if vim.fn.confirm(prompt, "&No\n&Yes", 1) ~= 2 then return end

  git.discard(path, item.section == "untracked", function(ok, err)
    if ok then
      vim.notify("Discarded: " .. path, vim.log.levels.INFO)
      M.refresh()
    else
      vim.notify("Discard failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

local function get_conflicted_item()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then return nil end
  if item.section ~= "conflicted" then return nil end
  return item
end

--- Save file content to undo stack before a per-conflict resolve.
local function save_conflict_undo(path)
  local cwd = vim.fn.getcwd()
  local full_path = cwd .. "/" .. path
  local ok, lines = pcall(vim.fn.readfile, full_path)
  if not ok then return end
  if not state.conflict_history[path] then
    state.conflict_history[path] = { undo = {}, redo = {} }
  end
  local hist = state.conflict_history[path]
  table.insert(hist.undo, lines)
  hist.redo = {} -- new action clears redo
end

--- If the diff panel has focus and cursor is on a conflict block, return its index.
---@return number|nil conflict_idx 1-based index of the conflict under cursor
local function get_conflict_at_diff_cursor()
  local ui_state = ui.get_state()
  if not ui_state.diff_win or not vim.api.nvim_win_is_valid(ui_state.diff_win) then
    return nil
  end
  if vim.api.nvim_get_current_win() ~= ui_state.diff_win then
    return nil
  end
  local cursor_line = vim.api.nvim_win_get_cursor(ui_state.diff_win)[1]
  return ui_state.display_to_conflict_idx and ui_state.display_to_conflict_idx[cursor_line] or nil
end

local function resolve_conflict(strategy, success_msg)
  local item = get_conflicted_item()
  if not item then return end

  local path = item.file.actual_path
  local conflict_idx = get_conflict_at_diff_cursor()

  if conflict_idx then
    -- Per-conflict resolution from diff panel
    save_conflict_undo(path)
    git.resolve_single_conflict(path, conflict_idx, strategy, function(ok, err)
      if ok then
        local total = ui.get_state().conflict_count or 0
        vim.notify(
          string.format("%s (#%d/%d): %s", success_msg, conflict_idx, total, path),
          vim.log.levels.INFO
        )
        M.refresh()
      else
        vim.notify("Resolve failed: " .. err, vim.log.levels.ERROR)
      end
    end)
  else
    -- Whole-file resolution from status panel
    git.resolve_conflict(path, strategy, function(ok, err)
      if ok then
        vim.notify(success_msg .. ": " .. path, vim.log.levels.INFO)
        M.refresh()
      else
        vim.notify("Resolve failed: " .. err, vim.log.levels.ERROR)
      end
    end)
  end
end

function M.resolve_conflict_ours()
  resolve_conflict("ours", "Accepted current changes")
end

function M.resolve_conflict_theirs()
  resolve_conflict("theirs", "Accepted incoming changes")
end

function M.resolve_conflict_both()
  local item = get_conflicted_item()
  if not item then return end

  local path = item.file.actual_path
  local conflict_idx = get_conflict_at_diff_cursor()

  if conflict_idx then
    -- Per-conflict "both" from diff panel
    save_conflict_undo(path)
    git.resolve_single_conflict(path, conflict_idx, "both", function(ok, err)
      if ok then
        local total = ui.get_state().conflict_count or 0
        vim.notify(
          string.format("Accepted both changes (#%d/%d): %s", conflict_idx, total, path),
          vim.log.levels.INFO
        )
        M.refresh()
      else
        vim.notify("Resolve failed: " .. err, vim.log.levels.ERROR)
      end
    end)
  else
    -- Whole-file "both"
    git.resolve_conflict_both(path, function(ok, err)
      if ok then
        vim.notify("Accepted both changes: " .. path, vim.log.levels.INFO)
        M.refresh()
      else
        vim.notify("Resolve both failed: " .. err, vim.log.levels.ERROR)
      end
    end)
  end
end

function M.mark_conflict_resolved()
  local item = get_conflicted_item()
  if not item then return end

  local path = item.file.actual_path
  git.stage(path, function(ok, err)
    if ok then
      vim.notify("Marked resolved: " .. path, vim.log.levels.INFO)
      M.refresh()
    else
      vim.notify("Mark resolved failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.undo_conflict()
  local item = get_conflicted_item()
  if not item then return end

  local path = item.file.actual_path
  local hist = state.conflict_history[path]
  if not hist or #hist.undo == 0 then
    vim.notify("Nothing to undo", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local full_path = cwd .. "/" .. path

  -- Save current state to redo
  local ok, current = pcall(vim.fn.readfile, full_path)
  if ok then
    table.insert(hist.redo, current)
  end

  -- Restore previous state
  local prev = table.remove(hist.undo)
  local ok_w, err = pcall(vim.fn.writefile, prev, full_path)
  if not ok_w then
    vim.notify("Undo failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.notify("Undid conflict resolution", vim.log.levels.INFO)
  M.refresh()
end

function M.redo_conflict()
  local item = get_conflicted_item()
  if not item then return end

  local path = item.file.actual_path
  local hist = state.conflict_history[path]
  if not hist or #hist.redo == 0 then
    vim.notify("Nothing to redo", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local full_path = cwd .. "/" .. path

  -- Save current state to undo
  local ok, current = pcall(vim.fn.readfile, full_path)
  if ok then
    table.insert(hist.undo, current)
  end

  -- Apply redo state
  local next_state = table.remove(hist.redo)
  local ok_w, err = pcall(vim.fn.writefile, next_state, full_path)
  if not ok_w then
    vim.notify("Redo failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.notify("Redid conflict resolution", vim.log.levels.INFO)
  M.refresh()
end

function M.toggle_section()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "section" then return end
  state.sections[item.section].collapsed = not state.sections[item.section].collapsed
  M.render()
end

function M.do_commit()
  vim.ui.input({ prompt = "  Commit message: " }, function(msg)
    if not msg or msg == "" then return end
    git.commit(msg, function(ok, output)
      if ok then
        vim.notify("✓ " .. vim.trim(output):match("[^\n]*$"), vim.log.levels.INFO)
        M.refresh()
      else
        vim.notify("Commit failed: " .. output, vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.do_push()
  vim.notify("Pushing...", vim.log.levels.INFO)
  git.push(function(ok, output)
    if ok then
      vim.notify("✓ Pushed successfully", vim.log.levels.INFO)
      M.refresh()
    else
      vim.notify("Push failed: " .. output, vim.log.levels.ERROR)
    end
  end)
end

function M.do_pull()
  vim.notify("Pulling...", vim.log.levels.INFO)
  git.pull(function(ok, output)
    if ok then
      vim.notify("✓ Pulled successfully", vim.log.levels.INFO)
      M.refresh()
    else
      vim.notify("Pull failed: " .. output, vim.log.levels.ERROR)
    end
  end)
end

function M.show_branches()
  git.branches(function(branches)
    if #branches == 0 then
      vim.notify("No branches found", vim.log.levels.WARN)
      return
    end
    local items = {}
    for _, b in ipairs(branches) do
      table.insert(items, (b.current and "● " or "  ") .. b.name)
    end
    vim.ui.select(items, { prompt = " Switch branch:" }, function(_, idx)
      if not idx then return end
      local branch = branches[idx]
      if branch.current then return end
      git.checkout(branch.name, function(ok, output)
        if ok then
          vim.notify("Switched to " .. branch.name, vim.log.levels.INFO)
          M.refresh()
        else
          vim.notify("Checkout failed: " .. output, vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

function M.create_branch()
  vim.ui.input({ prompt = "  New branch name: " }, function(name)
    if not name or name == "" then return end
    git.create_branch(name, function(ok, output)
      if ok then
        vim.notify("Created branch " .. name, vim.log.levels.INFO)
        M.refresh()
      else
        vim.notify("Failed: " .. output, vim.log.levels.ERROR)
      end
    end)
  end)
end

---------------------------------------------------------------------------
-- Hunk operations
---------------------------------------------------------------------------

--- Extract the diff header and the target hunk from raw diff lines.
--- Uses stored raw_diff_lines (since the buffer no longer has diff prefixes).
---@return string|nil patch, table|nil item
function M.get_current_hunk_patch()
  local item = M.get_item_at_cursor()
  if not item or item.type ~= "file" then return nil, nil end

  local ui_state = ui.get_state()
  local raw_lines = ui_state.raw_diff_lines
  if not raw_lines or #raw_lines == 0 then return nil, nil end

  -- Parse raw diff lines into header + hunks
  local header_lines = {}
  local hunks = {}
  local current_hunk = nil

  for _, line in ipairs(raw_lines) do
    if line:match("^diff ") or line:match("^index ") or line:match("^%-%-%- ") or line:match("^%+%+%+ ") or line:match("^new file") or line:match("^deleted file") then
      table.insert(header_lines, line)
    elseif line:match("^@@") then
      if current_hunk then table.insert(hunks, current_hunk) end
      current_hunk = { line }
    elseif current_hunk then
      table.insert(current_hunk, line)
    end
  end
  if current_hunk then table.insert(hunks, current_hunk) end
  if #hunks == 0 then return nil, nil end

  -- Find which hunk based on cursor position in diff panel
  local target_hunk = hunks[1]
  if ui_state.diff_win and vim.api.nvim_win_is_valid(ui_state.diff_win) then
    local cursor_line = vim.api.nvim_win_get_cursor(ui_state.diff_win)[1]
    local hunk_idx = ui_state.display_to_hunk_idx[cursor_line]
    if hunk_idx and hunks[hunk_idx] then
      target_hunk = hunks[hunk_idx]
    end
  end

  local patch_lines = vim.list_extend({}, header_lines)
  vim.list_extend(patch_lines, target_hunk)
  return table.concat(patch_lines, "\n") .. "\n", item
end

function M.stage_hunk()
  local patch, item = M.get_current_hunk_patch()
  if not patch or not item then
    vim.notify("No hunk to stage", vim.log.levels.WARN)
    return
  end
  if item.section == "staged" then return end
  git.stage_hunk(patch, function(ok, err)
    if ok then
      M.refresh()
    else
      vim.notify("Stage hunk failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.unstage_hunk()
  local patch, item = M.get_current_hunk_patch()
  if not patch or not item then
    vim.notify("No hunk to unstage", vim.log.levels.WARN)
    return
  end
  if item.section ~= "staged" then return end
  git.unstage_hunk(patch, function(ok, err)
    if ok then
      M.refresh()
    else
      vim.notify("Unstage hunk failed: " .. err, vim.log.levels.ERROR)
    end
  end)
end

-- expose for init
M.cursor_to_first_file = cursor_to_first_file

return M
