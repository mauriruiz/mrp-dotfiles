# mrp-dotfiles

Minimal macOS dev environment for Go and Rust: **Ghostty → tmux → Neovim 0.12**.

## Principles

- The repo holds the real files and mirrors `$HOME`; `$HOME` only holds symlinks.
- No GNU Stow, no plugin managers beyond Neovim's builtin `vim.pack`, no TPM.
- One look everywhere: Gruvbox Dark Hard and the Lilex font, Zed-style (Ghostty, tmux, Neovim, git-ui).
- Each layer does one job:
  - **Ghostty** renders (fonts, colors, clipboard, OS integration).
  - **tmux** owns sessions (one per project), windows and panes; sessions survive terminal restarts.
  - **Neovim** edits, with native LSP at the core and ~20 lazily loaded plugins.
- Toolchain binaries win over editor-managed ones: rustup's `rust-analyzer`, `go install`ed `gopls`.
  Mason only fills gaps.

## Layout

```
GUIDE.md                   # keys, by task
.config/
├── ghostty/config.ghostty
├── tmux/
│   ├── tmux.conf
│   ├── sessionizer        # project picker (prefix f)
│   └── status.sh          # cpu / load / mem / disk / battery / clock
├── nvim/
│   ├── init.lua
│   ├── nvim-pack-lock.json # plugin lockfile (commit it)
│   ├── lua/config/        # options, keymaps, autocmds, LSP core, tmux navigation
│   ├── lua/plugins/       # init.lua = every dependency; one file per area
│   ├── after/lsp/         # per-server overrides (gopls, lua_ls)
│   ├── after/ftplugin/    # Go / Rust buffer-local keys
│   ├── snippets/          # a few Go snippets (blink.cmp)
│   └── git-ui.nvim/       # local Git UI plugin
└── aerospace/aerospace.toml
```

## Setup

```bash
brew install neovim tmux fzf zoxide ripgrep fd lazygit tree-sitter-cli
brew install --cask ghostty
rustup component add rust-analyzer clippy rustfmt
go install golang.org/x/tools/gopls@latest

git clone git@github.com:ruizzmaury/mrp-dotfiles.git ~/dev/mrp-dotfiles
for d in nvim tmux ghostty aerospace; do ln -s ~/dev/mrp-dotfiles/.config/$d ~/.config/$d; done
```

Ghostty reads `~/.config/ghostty/config.ghostty`, but a file in
`~/Library/Application Support/com.mitchellh.ghostty/` is loaded **after** it and wins.
Keep that directory empty. Reload with `cmd+shift+,`.

The first `nvim` start installs plugins from the lockfile, compiles treesitter parsers and
installs the missing tools through Mason (delve, gotestsum, golangci-lint, codelldb, stylua).
For delve on macOS, run `sudo DevToolsSecurity -enable` once so it doesn't ask for
authorization on every debug session.

Put Go's bin directory on your shell PATH too (`export PATH="$HOME/go/bin:$PATH"`); Neovim
adds it for itself.

## Keys

See [GUIDE.md](GUIDE.md): every key by task, across Neovim and tmux.

## Behaviour worth knowing

- **Format on save:** Go (gopls: organize imports, then gofmt) and Rust (rustfmt through
  rust-analyzer) always. Lua, JS/TS/JSON/HTML/CSS and C# only when the project has a stylua,
  prettier or csharpier config, so shared repos don't get reformatted by surprise.
  `<leader>uf` turns it off.
- **Linting:** gopls runs the staticcheck suite as you type. golangci-lint runs on save only
  in repos that have a `.golangci.*` config. Clippy replaces `cargo check` in rust-analyzer.
- **rust-analyzer** builds into `target/rust-analyzer`, so it never blocks your
  `cargo build` in another pane (at the cost of extra disk).
- **neotest** only discovers tests in open files; project-wide discovery is too slow in large
  monorepos. Go tests run through gotestsum with `-race`.
- **Messages** use Neovim 0.12's experimental `ui2` (no "Press ENTER" prompts with
  `cmdheight=0`). Delete the `ui2` line in `lua/config/options.lua` to go back.

## Maintenance

- `:PackUpdate` reviews plugin updates (`:w` applies them); commit `nvim-pack-lock.json`.
  To roll back: `git checkout -- .config/nvim/nvim-pack-lock.json`, then run
  `vim.pack.update(nil, { target = "lockfile" })`.
- Add or remove a plugin in `lua/plugins/init.lua`, then run `:PackClean` for removed ones.
- `:checkhealth vim.lsp`, `:lsp` (manage clients), `:Mason`, `:TSUpdate`.
