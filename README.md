```
  .     .         .
  |     |    ,- o |
,-| ,-. |-   |  . | ,-. ,-.
| | | | |    |- | | |-' `-.
`-' `-' `-'  |  ' ' `-' `-'
            -'
```

zsh + tmux + neovim, on macOS / Apple Silicon.

- [Installation](#installation)
  - [What bootstrap.sh does](#what-bootstrapsh-does)
- [How the linking works](#how-the-linking-works)
- [What's tracked](#whats-tracked)
- [Daily use](#daily-use)
  - [zsh](#zsh)
  - [tmux](#tmux)
  - [vim / neovim](#vim--neovim)
  - [git](#git)
- [Adding a new dotfile](#adding-a-new-dotfile)
- [Terminal setup](#terminal-setup)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Installation

On a fresh machine:

```bash
git clone git@github.com:lyosha-v/dotfiles.git
cd dotfiles
./bootstrap.sh
```

Then open a new terminal. Two manual steps are left, because neither can be
scripted: sign in to 1Password and turn on its SSH agent (commit signing needs
it), and run `gh auth login`.

Clone it wherever you like — the scripts resolve their own location. The
symlinks they create do point at wherever the repo sat when you ran them, so
moving the repo afterwards means re-running `./install.sh`.

### What bootstrap.sh does

Every step checks before it acts and skips what is already done, so it is also
the "bring this machine up to date" script, not just a first-run one.

| Step | |
| --- | --- |
| Xcode CLT | Homebrew needs them, and its installer otherwise blocks on a GUI prompt |
| Homebrew | installs it, then puts it on `$PATH` for the rest of the run |
| `Brewfile` | `brew bundle` — every package this setup uses, listed in one file |
| [oh-my-zsh](https://ohmyz.sh) | with `KEEP_ZSHRC=yes`, so it can't clobber the `.zshrc` about to be linked |
| `install.sh` | links the dotfiles |
| node | `nvm install --lts` — `.zshrc` lazy-loads nvm but installs nothing |
| [vim-plug](https://github.com/junegunn/vim-plug) | `nvim --headless +PlugInstall` |
| [tpm](https://github.com/tmux-plugins/tpm) | clones it and installs the tmux plugins |
| history | imports existing `~/.zsh_history` into atuin and `~/.z` into zoxide |

To install just the packages, without touching anything else:

```bash
brew bundle install --file=Brewfile
brew bundle check  --file=Brewfile --verbose   # what's missing or outdated
```

## How the linking works

`install.sh` **symlinks** every top-level dotfile into `$HOME`:

```
~/.zshrc  ->  <repo>/.zshrc
```

so editing either path edits the same file, and `git status` in this repo is an
honest account of what your machine is actually running.

This matters because it used to use *hard* links. Most editors save by writing a
temp file and renaming it over the target, which severs a hard link — so edits
landed in `$HOME` only, the repo silently drifted years out of date, and
`git status` stayed clean the whole time. If you ever see this repo disagree
with `$HOME`, that's the failure mode to suspect.

```
./install.sh                  link every tracked dotfile into $HOME (default)
./install.sh adopt FILE...    move FILE into the repo, then link it back
```

The script is safe to re-run:

- a correct symlink is left alone (`ok`)
- anything else in the way is moved to `<file>.backup-<timestamp>`, never deleted
- `*.terminfo` files are compiled with `tic -x` instead of being linked

```
$ ./install.sh
ok       .tmux.conf
ok       .zshrc
backup   .vimrc -> .vimrc.backup-20260916-204309
link     .vimrc
tic      ./tmux-256color.terminfo
```

## What's tracked

| File | Contents |
| --- | --- |
| `.zshrc` | oh-my-zsh, lazy nvm, fzf, zoxide, atuin, eza, bat, autosuggestions, highlighting |
| `.zprofile` | Homebrew `shellenv`, `$PATH` de-duplication, Docker |
| `.vimrc` | plugins, LSP, ALE, catppuccin, mappings — read by both vim and nvim |
| `.gitconfig` | identity, 1Password SSH signing, delta, aliases |
| `.tmux.conf` | `C-a` prefix, vi keys, tpm plugins |
| `.bashrc` | fzf only; bash is not the daily shell |
| `Brewfile` | every package the setup needs |
| `bootstrap.sh` | fresh-machine setup; `install.sh` links, this installs |
| `*.terminfo` | italic-capable terminal descriptions, compiled by `install.sh` |

**Not yet tracked**, though they are part of the setup:

- `~/.config/nvim/init.vim` — four lines that point neovim at `~/.vimrc`
- `~/.config/ripgrep/config` — global search excludes, via `$RIPGREP_CONFIG_PATH`
- `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`

The first two would need `install.sh` to handle nested paths (see
[Adding a new dotfile](#adding-a-new-dotfile)); the third lives outside `$HOME`'s
top level entirely.

### Machine-local overrides

`.zshrc` sources these at the end if they exist, and neither is tracked — put
anything work-specific or secret in them:

- `~/.zshrc_local`
- `~/.fzf_zsh`

## Daily use

### zsh

| | |
| --- | --- |
| `z <fragment>` | jump to a frecently-visited directory (zoxide) |
| `zi` | same, but pick from a list |
| `ls` `ll` `la` `lt` | eza — plain, long+git, long+hidden, tree |
| `cat` / `bat` | `cat` is left alone; `bat` adds highlighting and line numbers |
| `lg` | lazygit |
| `tn` | new tmux session named after the current directory |
| `ta` | attach to a session, detaching other clients |
| `tl` | list sessions |
| `cdr` | cd to the repo root |
| `gdmn` | files changed against the repo's default branch |
| `vim` / `vi` | both aliased to `nvim` |

| Key | |
| --- | --- |
| `C-r` | history search (atuin) — fuzzy, deduplicated, scoped by directory |
| `C-t` | fuzzy file picker into the current command |
| `M-c` | fuzzy cd |
| `→` | accept the autosuggestion |
| `M-f` | accept one word of it |
| `C-q` | stash the current line, run something else, get it back |

Up-arrow is deliberately left as ordinary zsh prefix search rather than handed
to atuin, so the two kinds of recall stay distinct.

`$FZF_DEFAULT_COMMAND` is `rg --files --hidden`, so pickers see dotfiles and
respect `.gitignore`; `M-c` uses `fd --type d` because it needs directories.
Previews render through `bat`.

### tmux

Prefix is **`C-a`** (not `C-b`). Send a literal `C-a` with `C-a C-a`.

| | |
| --- | --- |
| `C-a h/j/k/l` | move between panes |
| `C-a [` | copy mode — vi keys, `v` select, `y` yank |
| `C-a I` | install plugins after editing `.tmux.conf` |
| `C-a f` | fpp — pick a file path off the screen and open it |

Mouse mode is on: click panes, drag borders, scroll natively.

### vim / neovim

Leader is **space**. `~/.vimrc` is the single config; neovim reads it through
`~/.config/nvim/init.vim` and additionally gets LSP and Claude Code, both gated
behind `has('nvim')`.

**Navigation**

| | |
| --- | --- |
| `C-p` | fuzzy file picker |
| `C-f` | ripgrep across the project |
| `;` | buffer list |
| `<leader>f` | reveal the current file in NERDTree |
| `[b` / `]b` | previous / next buffer |
| `[q` / `]q` | previous / next quickfix entry |
| `<CR>` | clear search highlight |

In any fzf picker, `C-t` opens in a tab, `C-x` splits, `C-v` vsplits.

**Editing and diagnostics**

| | |
| --- | --- |
| `[e` / `]e` | previous / next ALE problem |
| `ff` | run ALE fixers (prettier, eslint, importjs) |
| `ar` | restart ALE |
| `gcc` / `gc{motion}` | toggle comments (tComment) |

**LSP** (neovim only — TypeScript via `ts_ls`, Swift via `sourcekit` when present)

| | |
| --- | --- |
| `gd` | go to definition |
| `gy` | go to type definition |
| `gr` | references |
| `K` | hover |
| `<leader>rn` | rename symbol |
| `<leader>ca` | code action |

**git** (fugitive)

| | |
| --- | --- |
| `<leader>gb` | blame the current line |
| `<leader>gd` | diff against the index |
| `<leader>gst` | status |
| `<leader>gc` | commit |

Changed lines are marked in the gutter by vim-gitgutter.

**Claude Code** (neovim only). Claude runs in its own tmux window; nvim acts as
the IDE peer that supplies context and renders diffs, so there is deliberately
no terminal-toggle mapping.

| | |
| --- | --- |
| `<leader>ab` | add the current buffer to context |
| `<leader>as` | send the visual selection |
| `<leader>aa` / `<leader>ad` | accept / deny the proposed diff |
| `<leader>aq` | close all pending diffs |
| `<leader>a?` | connection status |

**Theme.** Catppuccin, following the macOS appearance — Latte in light mode,
Mocha in dark. It re-checks on `FocusGained`, so switching the system theme and
clicking back into vim is enough; no restart.

### git

| | |
| --- | --- |
| `git st` | status |
| `git co` | checkout |
| `git ci` | commit |
| `git br` | branch |
| `git lg` | graph log, wrapped to 80 columns |
| `git dt` | difftool (vimdiff) |
| `lg` (shell) | lazygit — staging hunks interactively beats `git add -p` |

Diffs page through [delta](https://github.com/dandavison/delta): syntax
highlighted, with line numbers, moved lines distinguished from added and removed
ones, and `n`/`N` to jump between files. It follows the terminal background, so
it matches bat, vim and Ghostty.

Behaviour worth knowing, since it differs from stock git:

| | |
| --- | --- |
| `merge.conflictStyle = zdiff3` | conflicts show the common ancestor, not just both sides |
| `rerere.enabled` | a conflict resolved once is replayed automatically next time |
| `rebase.autostash` | rebasing with a dirty tree stashes and restores by itself |
| `rebase.autosquash` | `fixup!` commits are folded in without `-i` fiddling |
| `fetch.prune` | deleted remote branches stop lingering locally |
| `pull.ff = only` | a pull that isn't fast-forward stops instead of merging |
| `push.default = current` | `git push` needs no arguments |
| `diff.algorithm = histogram` | more readable diffs on refactors |

Commits are SSH-signed through the 1Password agent
(`gpg.ssh.program = op-ssh-sign`, `commit.gpgsign = true`), which means **every
commit triggers a 1Password approval**. Automation that commits on your behalf
needs `-c commit.gpgsign=false`, or an unlocked agent.

## Adding a new dotfile

```bash
./install.sh adopt ~/.newrc
git add .newrc && git commit
```

`adopt` moves the file into the repo and links it straight back, so the copy you
were already using stays the one in effect — nothing to reconcile afterwards. It
refuses rather than clobbers if the repo already has a file by that name, and
tells you to diff the two.

The plain `./install.sh` can't do this for you, because it only knows about
files already in the repo; adopting runs the other direction and needs to be
told which file you mean.

`install.sh` only walks the top level (`find . -maxdepth 1`). A file that
belongs under `~/.config/…` needs either a nested-path-aware installer or
[GNU Stow](https://www.gnu.org/software/stow/), which handles that case for
free:

```bash
brew install stow
```

## Terminal setup

[Ghostty](https://ghostty.org), configured separately in
`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`:

- `theme = light:Catppuccin Latte,dark:Catppuccin Mocha` — follows macOS, and
  matches what `.vimrc` does, so the two never disagree
- JetBrains Mono 13 — installed by the `Brewfile` as `font-jetbrains-mono`.
  Ghostty falls back silently when a configured font is missing, so a missing
  cask looks like "the config didn't apply" rather than an error.
- `⌘D` / `⌘⇧D` split, `⌘h/j/k/l` move, `⌘⇧↵` zoom
- `macos-option-as-alt = true`, which is what makes `M-c` and `M-f` above work

`.tmux.conf` sets `default-terminal tmux-256color` and overrides `sitm` so
italics survive inside tmux. The tracked `*.terminfo` files exist for terminals
that need `xterm-256color-italic` declared explicitly; Ghostty does not.

## Troubleshooting

**A config change didn't take effect.** Confirm the file is still a symlink —
`ls -l ~/.zshrc` should point into this repo. If it's a regular file, something
replaced it; re-run `./install.sh`.

**A brew-installed tool resolves to the macOS one.** `.zprofile` prepends
`brew shellenv` to fix the general case, but keg-only formulae (curl, openssl,
libpq) are never linked into `/opt/homebrew/bin` at all and need their own
entry:

```bash
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
```

**`ls` hangs.** `ls`/`ll`/`la`/`lt` are shell *functions*, not aliases, because
eza 0.23.5 hangs forever when run with no path argument — `eza .` returns
instantly, bare `eza` never returns. The functions pass an explicit `.` when
given no argument. If a later eza fixes this, they can go back to being plain
aliases.

**Slow shell startup.** nvm is lazy-loaded, so this should sit near 0.1s. If it
creeps up, profile by bracketing `.zshrc` with
`zmodload zsh/zprof` on the first line and `zprof` on the last, then starting a
shell.

**`q` and `'` don't do what vim says they do.** `.vimrc` maps `q` to `:cclose`
and `'` to `:!jest %`, which shadows macro recording and mark-jumping
respectively. Deliberate, but surprising if you sit down at this config
expecting stock vim.

**Colors look wrong over ssh or in tmux.** The remote end needs the
`tmux-256color` entry; `install.sh` compiles it locally with `tic -x`.

## License

> MIT License

&copy; 2014-2026 Lyosha Verkholantcev
