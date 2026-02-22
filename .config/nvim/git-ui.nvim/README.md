# git-ui.nvim

A VSCode-like Git UI for Neovim. Stage, discard, diff, commit, push, pull and switch branches without leaving your editor.

## Open / Close

`<leader>gg` toggles the Git UI. It opens in its own tab.

Use `gt` / `gT` to switch between the Git UI tab and your code tabs.

## Layout

```
┌──────────────────┬────────────────────────────────┬──┐
│  Status Panel    │  Diff (full file view)         │▓▓│
│                  │                                │░░│
│   branch       │  syntax-highlighted code       │██│ ← green = addition
│                  │  with changes colored:         │░░│
│  ▼ Staged (n)    │    green bg = added lines      │▒▒│ ← red = deletion
│    ✓ file.go     │    red bg   = removed lines    │░░│
│  ▼ Changes (n)   │                                │▓▓│ ← lighter = viewport
│    ~ file.lua    │  unchanged lines show normal   │░░│ ← dark = track
│  ▼ Untracked (n) │  syntax colors (Go, Lua, etc)  │░░│
│    ? new.txt     │                                │░░│
└──────────────────┴────────────────────────────────┴──┘
 status panel       diff preview                  scrollbar
```

## Keymaps

### Status panel (left)

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate files (diff updates live) |
| `s` | Stage file |
| `u` | Unstage file |
| `d` | Discard file changes (or delete untracked file) |
| `S` | Stage all |
| `U` | Unstage all |
| `c` | Commit (prompts for message) |
| `P` | Push |
| `L` | Pull |
| `b` | Switch branch |
| `n` | Create new branch |
| `r` | Refresh |
| `<CR>` | Collapse / expand section |
| `<Tab>` | Jump to diff panel |
| `q` / `<Esc>` | Close Git UI |

### Diff panel (right)

| Key | Action |
|-----|--------|
| `]c` | Jump to next change block |
| `[c` | Jump to previous change block |
| `hs` | Stage hunk under cursor |
| `hu` | Unstage hunk under cursor |
| `<Tab>` / `<Esc>` | Back to status panel |
| `q` | Close Git UI |

## Config

Override defaults in `lua/plugins/git-ui.lua`:

```lua
opts = {
  layout = { status_width = 50 },
  keymaps = {
    open = "<leader>gs",
    commit = "cc",
    push = "gp",
  },
  icons = {
    branch = "",
    staged = "✓",
    modified = "~",
    added = "+",
    deleted = "-",
    untracked = "?",
  },
}
```
