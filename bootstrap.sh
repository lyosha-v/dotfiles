#!/usr/bin/env bash
#
# One command to take a fresh macOS machine to a working setup:
#
#   ./bootstrap.sh
#
# Installs Homebrew, everything in the Brewfile, oh-my-zsh, then links the
# dotfiles. Safe to re-run -- every step checks first and skips work already
# done, so it doubles as a "bring this machine up to date" script.

set -euo pipefail

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
skip() { printf '    already done: %s\n' "$1"; }

if [ "$(uname)" != "Darwin" ]; then
    echo "bootstrap.sh targets macOS; on anything else install the Brewfile contents by hand" >&2
    exit 1
fi

# ── Xcode command line tools ─────────────────────────────────────────────────
# Homebrew needs these, and its own installer will block on a GUI prompt for
# them, so get it over with first.
step "Xcode command line tools"
if xcode-select -p >/dev/null 2>&1; then
    skip "$(xcode-select -p)"
else
    xcode-select --install
    echo "    Finish the GUI installer, then re-run this script."
    exit 1
fi

# ── Homebrew ─────────────────────────────────────────────────────────────────
step "Homebrew"
if command -v brew >/dev/null 2>&1; then
    skip "$(brew --version | head -1)"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Homebrew registers itself in /etc/paths.d, but path_helper appends those, so
# they land behind /usr/bin. .zprofile fixes this permanently; this line is so
# the rest of *this* script can see brew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── Packages ─────────────────────────────────────────────────────────────────
step "Brewfile"
brew bundle install --file="$DOTFILES_DIR/Brewfile" --no-lock

# ── oh-my-zsh ────────────────────────────────────────────────────────────────
# .zshrc sources this; without it the shell errors on every start.
step "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    skip "$HOME/.oh-my-zsh"
else
    # RUNZSH=no stops the installer from dropping into a subshell and stalling
    # the script; KEEP_ZSHRC stops it overwriting the .zshrc we are about to link.
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ── Dotfiles ─────────────────────────────────────────────────────────────────
step "Linking dotfiles"
"$DOTFILES_DIR/install.sh"

# ── nvm ──────────────────────────────────────────────────────────────────────
# .zshrc lazy-loads nvm but does not install a node for it to find.
step "node"
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
# shellcheck disable=SC1091
. /opt/homebrew/opt/nvm/nvm.sh
if [ -n "$(nvm ls --no-colors 2>/dev/null | grep -v 'N/A' | grep -o 'v[0-9]' | head -1)" ]; then
    skip "$(nvm current)"
else
    nvm install --lts
fi

# ── Editor plugins ───────────────────────────────────────────────────────────
step "vim plugins"
# vim-plug self-installs from .vimrc, but PlugInstall still has to be run once.
nvim --headless +PlugInstall +qall 2>/dev/null || \
    echo "    run :PlugInstall inside nvim if this did not take"

step "tmux plugins"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    skip "tpm"
else
    git clone --quiet https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || \
    echo "    press C-a I inside tmux if this did not take"

# ── Data migration ───────────────────────────────────────────────────────────
# Only meaningful when moving from an older setup; both are no-ops otherwise.
step "History"
if command -v atuin >/dev/null 2>&1; then
    atuin import auto >/dev/null 2>&1 && echo "    imported shell history into atuin"
fi
if command -v zoxide >/dev/null 2>&1 && [ -f "$HOME/.z" ]; then
    zoxide import z --merge < "$HOME/.z" && echo "    imported ~/.z into zoxide"
fi

cat <<'DONE'

==> Done.

    Open a new terminal. Remaining manual steps:
      - sign in to the 1Password app and enable the SSH agent (commit signing)
      - gh auth login
DONE
