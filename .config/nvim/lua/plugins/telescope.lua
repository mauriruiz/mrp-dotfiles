return {
  {
    'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
    cmd = "Telescope",
    keys = {
      { "<C-p>", desc = "Find files" },
      { "<leader>fg", desc = "Live grep (literal)" },
      { "<leader>fG", desc = "Live grep (regex)" },
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require("telescope.builtin")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- <C-r> inside any grep picker: enter replace mode
      local function enter_replace(prompt_bufnr)
        local ok, err = pcall(function()
          local search_term = action_state.get_current_line()
          if not search_term or search_term == "" then
            vim.notify("No search term entered", vim.log.levels.WARN)
            return
          end
          actions.close(prompt_bufnr)
          vim.schedule(function()
            package.loaded["telescope-replace"] = nil
            local replace = require("telescope-replace")
            replace.open(search_term)
          end)
        end)
        if not ok then
          vim.notify("Replace error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end

      -- Open grep entry and force cursor to land on the matched line/col,
      -- defeating any autocmd (LSP attach, treesitter, etc.) that moves cursor
      -- after BufRead.
      local function open_at_match(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then return end

        local filename = entry.filename or entry.path or entry.value
        local lnum = entry.lnum or entry.row
        local col = (entry.col or 1)
        if not filename then return end

        vim.cmd("edit " .. vim.fn.fnameescape(filename))
        if not lnum then return end

        local function jump()
          local total = vim.api.nvim_buf_line_count(0)
          local target = math.min(lnum, total)
          pcall(vim.api.nvim_win_set_cursor, 0, { target, math.max(0, col - 1) })
          vim.cmd("normal! zz")
        end

        -- Defer twice: once for BufRead-triggered autocmds, once after
        -- treesitter/LSP fold-on-attach has settled.
        vim.schedule(jump)
        vim.defer_fn(jump, 50)
      end

      local function grep_mappings(prompt_bufnr, map)
        -- Use vim.keymap.set directly with nowait to override Vim's built-in
        -- insert-mode <C-r> (insert from register) which eats the first press
        vim.keymap.set("i", "<C-r>", function()
          enter_replace(prompt_bufnr)
        end, { buffer = prompt_bufnr, nowait = true })
        vim.keymap.set("n", "<C-r>", function()
          enter_replace(prompt_bufnr)
        end, { buffer = prompt_bufnr, nowait = true })

        -- Override default select to guarantee jump-to-match
        actions.select_default:replace(function()
          open_at_match(prompt_bufnr)
        end)
        return true
      end

      vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Find files" })

      vim.keymap.set('n', '<leader>fg', function()
        builtin.live_grep({
          additional_args = function() return { "--fixed-strings" } end,
          attach_mappings = grep_mappings,
        })
      end, { desc = "Live grep (literal)" })

      vim.keymap.set('n', '<leader>fG', function()
        builtin.live_grep({
          attach_mappings = grep_mappings,
        })
      end, { desc = "Live grep (regex)" })
    end,
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = {
            width = 0.95,
            height = 0.85,
            preview_width = 0.55,
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }
          }
        }
      })
      require("telescope").load_extension("ui-select")
    end
  },
}
