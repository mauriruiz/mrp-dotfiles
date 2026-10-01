local opt = vim.opt

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true
opt.virtualedit = "block"
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 200
opt.timeoutlen = 400
opt.jumpoptions = "stack,view,clean"

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "both"
opt.wrap = false
opt.linebreak = true
opt.smoothscroll = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.laststatus = 3
opt.cmdheight = 0
opt.showmode = false
opt.ruler = false
opt.pumheight = 12
opt.winborder = "rounded"
opt.shortmess:append({ I = true, c = true, W = true })
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = { eob = " ", diff = "╱", fold = " ", foldopen = "\u{f47c}", foldclose = "\u{f460}", foldsep = " " }
opt.completeopt = "menu,menuone,noselect,popup,fuzzy"

-- Folds: treesitter-driven, open by default
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

opt.wildoptions = "pum,fuzzy"
opt.wildmode = "longest:full,full"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- Experimental in 0.12, but it is the core fix for cmdheight=0 (no hit-enter prompts).
-- Remove this line to fall back to the legacy message grid.
pcall(function() require("vim._core.ui2").enable({ msg = { targets = "msg" } }) end)

-- Clipboard provider detection shells out; keep it off the startup path.
vim.schedule(function() opt.clipboard = "unnamedplus" end)
