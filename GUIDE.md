# Guide

Leader is `Space`, local leader is `\`. Forgot a key? Press `Space` and wait for the popup,
or search every mapping with `Space f k`.

## Move around

| Key | Does |
|---|---|
| `C-h/j/k/l` | Move between Neovim splits and tmux panes, as one grid |
| `C-p` / `Space f f` | Find file |
| `Space f g` / `Space f G` | Grep the project (literal / regex) |
| `Space f w` | Grep the word under the cursor (or the selection) |
| `Space f b` / `Space f r` | Open buffers / recent files |
| `[b` `]b` | Previous / next buffer |
| `Space b d` / `Space b o` | Close buffer / close all others |
| `C-o` / `C-i` | Jump back / forward |

Inside any picker: `C-j`/`C-k` move, `Enter` opens, `C-v`/`C-s` open in a split,
`C-q` sends the results to quickfix, `alt-.` shows hidden files. Inside grep, `C-r` turns the
search into a project-wide replace and `C-s` narrows it to one directory.

## File tree

`C-b` (or `Space e`) toggles the tree, `C-n` reveals the current file in it. `nvim .` opens it.

| Key | Does |
|---|---|
| `a` / `A` | New file (end with `/` for a folder) / new folder |
| `r` `d` | Rename / delete |
| `c` `m` | Copy / move to a path |
| `y` `x` `p` | Copy / cut / paste |
| `H` | Show hidden files |
| `/` | Filter |
| `Backspace` / `.` | Up one folder / make this folder the root |
| `?` | All keys |

## Read and navigate code

| Key | Does |
|---|---|
| `gd` / `gD` | Definition / declaration |
| `grr` | References |
| `gri` / `grt` | Implementations / type definition |
| `gO` / `Space f S` | Symbols in file / in workspace |
| `K` | Hover docs (Rust: with actions) |
| `]]` `[[` | Next / previous use of the symbol under the cursor |
| `]m` `[m` | Next / previous function |
| `]d` `[d` / `]e` `[e` | Next / previous diagnostic / error |
| `C-w d` | Show the diagnostic under the cursor |
| `Space f d` | All diagnostics |

## Edit

| Key | Does |
|---|---|
| `Enter` / `Tab` `S-Tab` | Accept completion / cycle items and snippet fields |
| `C-Space` / `C-e` | Open / close completion |
| `C-k` (insert) | Signature help |
| `grn` | Rename symbol |
| `gra` | Code action (quick fixes, refactors) |
| `Space c f` | Format (Go and Rust also format on save) |
| `gc` / `gcc` | Comment selection / line |
| `af` `if` · `ac` `ic` · `aa` `ia` | Function · type · argument text objects (`daf`, `cia`, `vic`) |
| `v` then `an` / `in` | Grow / shrink the selection by syntax node |
| `sa` / `sd` / `sr` | Add / delete / replace surrounding (`saiw"`, `sd(`, `sr"'`) |
| `Space r r` / `Space r f` | Replace in project / in file, with preview |
| `Space f u` | Undo history |

Snippets: friendly-snippets, plus `iferr` and `errw` (wrap with `%w`) for Go.

## Go (`\` in a Go file)

| Key | Does |
|---|---|
| `\t` / `\T` | Add / remove struct tags (works on a selection) |
| `\f` / `\s` | Fill struct / fill switch |
| `\a` | Generate a test for the function |
| `\m` | `go mod tidy` |
| `\d` | Debug the test under the cursor |
| `\o` / `\A` | Show compiler optimizations (inlining, escapes) / browse assembly |
| `grx` | Run the code lens on the line (`go generate`, tidy, vulncheck in go.mod) |

Saving organizes imports and gofmts. golangci-lint runs on save when the repo has a
`.golangci.*` config.

## Rust (`\` in a Rust file)

| Key | Does |
|---|---|
| `\r` / `\t` / `\d` | Pick something to run / test / debug |
| `\e` / `\D` | Explain the error / show the full compiler diagnostic |
| `\m` | Expand the macro under the cursor |
| `\a` | Code actions, grouped |
| `\c` / `\p` / `\o` | Open Cargo.toml / parent module / docs.rs |
| `\j` | Join lines, Rust-aware |

Clippy runs on save. In `Cargo.toml`, `K` shows crate versions and `gra` upgrades them.

## Test and debug

| Key | Does |
|---|---|
| `Space t t` / `t f` / `t p` / `t a` | Run nearest test / file / package / everything |
| `Space t l` / `Space t d` | Rerun last / debug nearest |
| `Space t s` / `t o` / `t O` | Summary / output of the test / output panel |
| `Space t w` / `Space t S` | Rerun the file on save / stop |
| `Space d b` / `Space d B` | Breakpoint / conditional breakpoint |
| `Space d c` | Start or continue |
| `Space d o` / `d i` / `d O` | Step over / into / out |
| `Space d C` / `Space d l` | Run to cursor / rerun last session |
| `Space d h` / `Space d w` | Value under the cursor / watch it |
| `Space d u` / `Space d t` | Toggle the debug panel / stop |

## Git

| Key | Does |
|---|---|
| `Space g g` | git-ui: stage, diff, commit, push, branches, conflicts |
| `Space g l` / `Space g f` | Lazygit / history of this file |
| `Space g s` / `Space g d` | Changed files / changed hunks |
| `]h` `[h` | Next / previous hunk |
| `Space h s` / `h r` / `h p` | Stage / reset / preview hunk |
| `Space h b` / `Space g L` | Blame line / history of this line |
| `Space g B` | Open the file on GitHub |

## Terminals and AI

| Key | Does |
|---|---|
| `C-\` | Toggle a terminal (double `Esc` for normal mode) |
| `Space a c` | Toggle Claude Code on the right |
| `Space l d` | Lazydocker |

## Toggles

`Space u` then: `h` inlay hints · `d` diagnostics · `v` full diagnostic lines · `c` code lens ·
`f` format on save · `w` wrap · `s` spell.

## tmux (prefix `§`)

| Key | Does |
|---|---|
| `§ f` | Switch to a project (creates its session the first time) |
| `§ s` | Pick a session or window |
| `§ c` / `§ §` | New window / previous window |
| `§ \|` / `§ -` | Split right / below |
| `§ a` | Claude Code in a split |
| `§ z` / `§ x` | Zoom / close pane |
| `§ h/j/k/l` | Resize pane (repeat the key) |
| `§ H` / `§ L` | Move window left / right |
| `§ [` | Scroll and copy: `v` select, `y` copy to the system clipboard |
| `§ C-l` / `§ C-k` | Clear the screen / kill to end of line in a shell |
| `§ d` | Detach (sessions keep running) |
| `§ r` | Reload config |

## Plugins and tools

`Space p` then: `u` update plugins (review, `:w` to apply) · `c` remove unused ·
`m` Mason · `t` update treesitter parsers. `Space q r` restarts Neovim, `Space q q` quits.
