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

## Edit many places at once

| Instead of (VSCode) | Do |
|---|---|
| Cursors down a column | `C-v`, select down (`j` or `5j`), `I` type `Esc` (or `A` to append, `c` to replace) |
| Append to many line ends | `C-v`, select the lines, `$A` type `Esc` |
| `Cmd+D` on each match | `*` on the word, `cgn` type `Esc`, then `.` for the next one (`n` skips) |
| Change every match | `:%s/old/new/g` (`gc` asks each time; previews as you type) |
| Rename a symbol | `grn` (language-aware, across files) |
| Same edit on matching lines | `:g/pattern/normal A;` (any normal-mode keys) |

## Go and Rust (`\` in a Go or Rust file)

Same key, same meaning in both languages:

| Key | Go | Rust |
|---|---|---|
| `\e` | Show the error under the cursor | Same, with the compiler's full rendering |
| `\E` | Open the error's explanation page | `rustc --explain` for the error |
| `\d` | Debug the test under the cursor | Debug the item under the cursor |
| `\D` | Pick what to debug | Pick what to debug |
| `\r` | `go run` this package | Pick what to run (binaries, tests, examples) |
| `\a` | Code actions | Code actions, grouped |
| `\o` | Open docs in the browser | Open docs.rs |
| `\c` | Open `go.mod` | Open `Cargo.toml` |

Go only: `\t` / `\T` add / remove struct tags (works on a selection) · `\f` fill struct ·
`\s` fill switch · `\g` generate a test for the function · `\m` `go mod tidy` ·
`\i` show compiler decisions (inlining, escapes) · `\A` browse assembly · `grx` run the code lens
on the line (`go generate`; tidy and vulncheck in go.mod).

Rust only: `\m` expand macro · `\p` parent module · `\j` join lines · `K` hover with actions.
In `Cargo.toml`: `Space C v` / `C f` versions / features, `C u` / `C U` update / upgrade the crate,
`C a` upgrade all, `C t` toggle hints, `C r` reload.

On save, Go organizes imports and gofmts (plus golangci-lint when the repo has a `.golangci.*`
config); Rust runs rustfmt and clippy.

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
| `Space h b` / `Space g L` | Full blame for the line / history of this line |
| `Space u b` | Toggle the inline blame after the current line |
| `Space g B` | Open the file on GitHub |

## Terminals and AI

| Key | Does |
|---|---|
| `C-\` | Toggle a terminal (double `Esc` for normal mode) |
| `Space a c` | Toggle Claude Code on the right |
| `Space l d` | Lazydocker |

## Toggles

`Space u` then: `h` inlay hints · `d` diagnostics · `v` full diagnostic lines · `c` code lens ·
`f` format on save · `b` line blame · `w` wrap · `s` spell.

## tmux (prefix `§` or `` ` ``)

Both keys work as the prefix, so `§ c` and `` ` c `` are the same. Type a literal backtick with `` ` e ``.

| Key | Does |
|---|---|
| `§ f` | Switch to a project (creates its session the first time) |
| `§ s` | Pick a session or window |
| `§ c` / `§ §` (or `` ` ` ``) | New window / previous window |
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
