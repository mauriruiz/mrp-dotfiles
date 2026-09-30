# Neovim Guide

**Leader key = `Space`.** So `<leader>ff` means: press `Space`, then `f`, then `f`.

> Forgot a key? Press `Space` and wait. A popup lists every shortcut.
> `Space ?` shows only the shortcuts for the current file.

---

## 1. Start screen

Run `nvim` with no file to get the dashboard:

| Key | Does |
|-----|------|
| `f` | Find file |
| `n` | New file |
| `g` | Search text in project |
| `r` | Recent files |
| `c` | Open this config |
| `L` | Plugin manager (Lazy) |
| `q` | Quit |

`nvim .` opens the file explorer instead.

---

## 2. Basics

| Key | Does |
|-----|------|
| `Esc` | Clear search highlight |
| `Ctrl h/j/k/l` | Move to window left/down/up/right |
| `>` / `<` (visual) | Indent / unindent (keeps selection) |
| `+` / `-` | Increase / decrease number under cursor |
| `Space n` | Notification history |

Clipboard is shared with macOS: `y` copies, `p` pastes.

---

## 3. File explorer — `Ctrl b`

- `Ctrl b` opens / closes the sidebar (from anywhere).
- `Ctrl n` jumps between the file and the sidebar (opens it if closed).
- `Ctrl p` (find file) works inside it too.

Inside:

| Key | Does |
|-----|------|
| `Enter` / `l` | Open file / expand folder |
| `h` | Collapse folder |
| `Backspace` | Go up one folder |
| `a` | New file (end name with `/` for folder) |
| `r` | Rename |
| `d` | Delete |
| `c` / `m` | Copy / move |
| `y` then `p` | Yank then paste file |
| `H` / `I` | Toggle hidden / gitignored files |
| `P` | Toggle preview |
| `o` | Open with macOS app |
| `Z` | Collapse all |
| `q` / `Esc` | Close |

---

## 4. Find things (Telescope)

| Key | Does |
|-----|------|
| `Ctrl p` | Find file by name |
| `Space fg` | Search text (exact words) |
| `Space fG` | Search text (regex) |
| `Space fb` | Open buffers |
| `Space fd` | All diagnostics (errors/warnings) |
| `Space fs` | Search symbols (functions, structs…) |
| `Space fh` | Search Neovim help |
| `Space fr` | Reopen last search |

Inside any picker: type to filter, `Ctrl n` / `Ctrl p` to move, `Enter` to open, `Esc` to close.

### Search & replace across project
1. `Space fg`, type the text to find.
2. `Ctrl s` to limit the search to a folder (optional).
3. `Ctrl r` to switch to replace mode, then type the new text.
4. `Enter` replaces the selected match; `Ctrl a` replaces **all** of them.

---

## 5. Code (all languages)

These work when a language server is running (you'll see its name bottom-right in the status bar).

| Key | Does |
|-----|------|
| `K` | Docs for word under cursor |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | List all references |
| `Space rn` | Rename symbol everywhere |
| `Space ca` | Code actions (quick fixes) |
| `Space cf` | Format file |
| `Space e` | Show full error on this line |
| `]d` / `[d` | Next / previous error |
| `Space uh` | Toggle inlay hints (the grey type labels) |

**Auto-format on save:** Rust and Go only.

### Autocomplete (typing in insert mode)

| Key | Does |
|-----|------|
| `Tab` / `Shift Tab` | Next / previous suggestion (or jump in snippet) |
| `Enter` | Accept |
| `Ctrl e` | Close menu |
| `Ctrl Space` | Force open menu / toggle docs |
| `Ctrl b` / `Ctrl f` | Scroll docs |
| `Ctrl k` | Show function signature |

---

## 6. Rust 🦀

Open any `.rs` file inside a Cargo project. rust-analyzer starts on its own and runs **clippy** every time you save.

| Key | Does |
|-----|------|
| `K` | Hover docs + actions (cursor jumps into popup, `q` closes) |
| `Space rr` | Run something (binary, example…) |
| `Space rt` | Run a test |
| `Space rd` | Debug something (see section 7) |
| `Space rx` | Explain the error under cursor |
| `Space e` | Show the error the way `cargo` prints it |
| `Space ca` | Rust code actions |
| `Space rm` | Expand macro |
| `Space rc` | Open `Cargo.toml` |
| `Space rp` | Go to parent module |
| `Space rj` | Join lines (Rust-aware) |

### In `Cargo.toml`
Crate versions appear inline. Autocomplete suggests crate names and versions.

| Key | Does |
|-----|------|
| `Space Cv` | Show all versions of a crate |
| `Space Cf` | Show crate features |
| `Space Cu` | Update crate (compatible) |
| `Space CU` | Upgrade crate (latest) |
| `Space Ca` | Upgrade all crates |
| `Space Ct` | Toggle version hints |
| `Space Cr` | Reload |

---

## 7. Debugging

1. Put the cursor on a line → `Space db` (breakpoint).
2. `Space rd` → pick what to debug (Rust).
3. The debug panel opens on its own.

| Key | Does |
|-----|------|
| `Space db` | Toggle breakpoint |
| `Space dc` | Continue / start |
| `Space dn` | Step over (next line) |
| `Space di` | Step into |
| `Space do` | Step out |
| `Space dt` | Stop |
| `Space dv` | Show / hide debug panel |

---

## 8. Git

| Key | Does |
|-----|------|
| `Space lg` | LazyGit (full git UI) |
| `Space gg` | Git panel (built-in) |
| `]h` / `[h` | Next / previous changed block |
| `Space hp` | Preview change |
| `Space hs` | Stage change |
| `Space hr` | Undo change |
| `Space hb` | Who wrote this line (blame) |

Coloured bars in the left column = added / changed lines.

### Git panel (`Space gg`)
| Key | Does |
|-----|------|
| `s` / `u` | Stage / unstage file |
| `d` | Discard changes |
| `c` | Commit |
| `P` / `L` | Push / pull |
| `b` / `n` | Switch / new branch |
| `l` | Log |
| `Tab` | Jump to diff |
| `Enter` | Open / close section |
| `r` | Refresh |
| `q` | Close |
| `o` / `i` / `B` / `m` | Conflicts: ours / theirs / both / mark resolved |

---

## 9. Terminals & AI

| Key | Does |
|-----|------|
| `Ctrl \` | Toggle terminal |
| `Space t1` | Terminal on the right |
| `Space t2` | Terminal at the bottom |
| `Space tf` | Floating terminal |
| `Space ta` | Claude Code |
| `Space ot` | Toggle opencode |
| `Ctrl a` | Ask opencode about the code under cursor/selection |
| `Ctrl x` | opencode actions menu |
| `Space ld` | LazyDocker |

In a terminal: `Esc` returns to normal mode, `Ctrl h/j/k/l` moves to another window.

---

## 10. Markdown

| Key | Does |
|-----|------|
| `Space mp` | Live preview in browser |

Markdown files also render with styled headings, tables and checkboxes inside Neovim.

---

## 11. Maintenance

| Command | Does |
|---------|------|
| `:Lazy` | Plugin manager (`U` update, `S` sync) |
| `:Mason` | Install language servers / debuggers |
| `:ConformInfo` | Check formatters |
| `:checkhealth` | Diagnose problems |
| `:checkhealth vim.lsp` | Check language servers |
