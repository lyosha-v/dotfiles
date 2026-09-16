# Everything this setup needs, installable with `brew bundle` (or bootstrap.sh).
#
# Regenerate a superset of this from the current machine with:
#   brew bundle dump --force --describe
# though that captures everything installed, not just what these dotfiles use,
# so prefer editing this by hand.

# ── Shell ────────────────────────────────────────────────────────────────────
brew "zsh-autosuggestions"      # ghost-text completion from history
brew "zsh-syntax-highlighting"  # colors the command line as you type
brew "atuin"                    # searchable shell history, replaces C-r
brew "zoxide"                   # frecency-based `z`, replaces the z.sh script

# fzf-tab is cloned by bootstrap.sh into ~/.oh-my-zsh/custom/plugins, since it
# is an oh-my-zsh plugin rather than a formula.

# ── Editor / multiplexer ─────────────────────────────────────────────────────
brew "neovim"                   # `vim` and `vi` are aliased to this
brew "tmux"

# ── Search and file tools ────────────────────────────────────────────────────
brew "fzf"                      # C-t, C-r, M-c, and the vim :Files/:RG pickers
brew "ripgrep"                  # respects .gitignore; see .config/ripgrep/config
brew "fd"                       # find(1) replacement; backs fzf's M-c
brew "bat"                      # cat with syntax highlighting; fzf previews
brew "eza"                      # ls replacement with git status
brew "jq"                       # JSON

# ── Git ──────────────────────────────────────────────────────────────────────
brew "git-delta"                # diff pager, wired up in .gitconfig
brew "gh"                       # GitHub CLI
brew "lazygit"                  # terminal git UI, aliased to `lg`

# ── Languages / runtimes ─────────────────────────────────────────────────────
brew "nvm"                      # lazy-loaded in .zshrc; see `nvm install --lts`

# ── Misc ─────────────────────────────────────────────────────────────────────
brew "wget"
brew "curl"                     # keg-only; see the PATH note in README

# ── Casks ────────────────────────────────────────────────────────────────────
cask "ghostty"                  # terminal; config lives outside this repo
cask "1password-cli"            # backs the SSH commit signing in .gitconfig
cask "font-jetbrains-mono"      # the font Ghostty is configured to use
