# nvm --- {{{
# Deferred: sourcing nvm.sh eagerly costs ~250ms on every single shell start,
# which is most of zsh's startup. Instead, stub the commands that need it and
# let the first one pay the price. See
# http://www.growingwiththeweb.com/2018/01/slow-nvm-init.html
export NVM_DIR="$HOME/.nvm"
NVM_PREFIX=/opt/homebrew/opt/nvm

if [ -s "$NVM_PREFIX/nvm.sh" ] && [ ! "$(whence -w __init_nvm)" = function ]; then
    [ -s "$NVM_PREFIX/etc/bash_completion.d/nvm" ] && . "$NVM_PREFIX/etc/bash_completion.d/nvm"
    declare -a __node_commands=('nvm' 'node' 'npm' 'npx' 'pnpm' 'yarn')
    function __init_nvm() {
        for i in nvm node npm npx pnpm yarn; do unalias $i 2>/dev/null; done
        source "$NVM_DIR/nvm.sh"
        unset __node_commands
        unset -f __init_nvm
    }
    for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
fi
# }}}

export PATH="$HOME/.local/bin:$PATH"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

alias vim=nvim
alias vi=nvim

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="robbyrussell"

# fzf-tab turns every completion into an fzf picker. It has to load after
# compinit (oh-my-zsh runs it) and before zsh-autosuggestions, which is why it
# lives here rather than being sourced further down.
plugins=(git sublime npm node brew jsontools fzf-tab)

source $ZSH/oh-my-zsh.sh

# Returns whether the given command is executable or aliased.
RPROMPT="<- $(date '+%H:%M %d/%m/%y')"
autoload -U add-zsh-hook
add-zsh-hook zshaddhistory _update_rprompt

function _update_rprompt() {
    RPROMPT="<- $(date '+%H:%M %d/%m/%y')"
}

function _new_tmux_from_dir_name {
    tmux new-session -As `basename $PWD | sed s/\\\\./_/g`
}

# Opens a tmux session for a workspace directory and starts Claude Code in it,
# the way _new_tmux_from_dir_name opens a bare one for $PWD. The session is
# named after the directory, so running this again re-attaches to the session
# already there rather than starting a second claude. Without an argument it
# uses $PWD; anything after the directory is passed through to claude.
#
# A --worktree/-w passed through to claude names the session after the worktree
# instead, since that is the directory the session will actually be working in.
function _new_tmux_claude_workspace {
    # The directory is optional and defaults to $PWD, so a leading argument
    # only counts as one when it is not a flag; otherwise `tc --worktree foo`
    # from inside the repo would take --worktree for the directory. A directory
    # whose name really does start with a dash needs a ./ in front.
    local dir=$PWD
    if [[ -n $1 && $1 != -* ]]; then
        dir=$1
        shift
    fi
    if [[ ! -d $dir ]]; then
        print -u2 "${0}: not a directory: $dir"
        return 1
    fi
    dir=${dir:A}

    # claude puts a worktree at <repo>/.claude/worktrees/<name>; the name is
    # worth more as a session name than the repo's, which every worktree of the
    # repo would otherwise share. A bare --worktree lets claude pick the name,
    # which we cannot know here, so the repo name stays.
    local wt="" arg
    local -i i
    for (( i = 1; i <= $#; i++ )); do
        arg=$@[i]
        case $arg in
            --worktree=*|-w=*) wt=${arg#*=} ;;
            --worktree|-w)
                [[ -n $@[i+1] && $@[i+1] != -* ]] && wt=$@[i+1] ;;
        esac
    done

    # tmux reads a dot in a session name as a window/pane separator.
    local name=${${wt:-${dir:t}}//./_}

    if ! tmux has-session -t "=$name" 2>/dev/null; then
        # claude runs as the window's own command rather than being typed in
        # with send-keys, which races the shell's startup and loses the keys.
        # The trailing exec leaves a shell behind once claude exits, in the
        # worktree it created if there was one.
        #
        # The wrapper shell is interactive (-i) so that it hands the terminal to
        # claude: tmux's #{pane_current_path} is the directory of the terminal's
        # foreground process, and a non-interactive wrapper keeps that for
        # itself, so new panes would open in the repo rather than the worktree
        # claude moved into. -f skips the rc files an interactive shell loads.
        local after="exec ${SHELL:-/bin/zsh} -l"
        [[ -n $wt ]] && after="cd ${(q)dir}/.claude/worktrees/${(q)wt} 2>/dev/null; $after"
        local cmd="claude ${(j: :)${(q)@}}; $after"
        tmux new-session -d -s $name -c $dir "exec zsh -fic ${(q)cmd}"
    fi

    # Already inside tmux, attach would refuse to nest.
    if [[ -n $TMUX ]]; then
        tmux switch-client -t "=$name"
    else
        tmux attach -t "=$name"
    fi
}

function _has() {
  return $( whence $1 >/dev/null )
}

function _append_to_path() {
  if [ -d $1 -a -z ${path[(r)$1]} ]; then
    path=($1 $path);
  fi
}

function _execute_if_file_exists() {
    if [ -f "$1" ]; then
        source "$1";
    fi
}

NODE_MODULES=./node_modules/.bin

export PATH="$PATH:$NODE_MODULES"

export EDITOR="nvim"

# History --- {{{
# oh-my-zsh sets SAVEHIST well below HISTSIZE, which silently throws away most
# of what it just collected.
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_REDUCE_BLANKS
# }}}

# zoxide --- {{{
# Replaces `z`. Same idea and the same `z <fragment>` muscle memory, but it
# tracks frecency in a real database and adds `zi` for an interactive picker.
# Existing ~/.z entries were imported with: zoxide import z --merge < ~/.z
if _has zoxide; then
    eval "$(zoxide init zsh)"
fi
# }}}

# eza --- {{{
# Functions rather than aliases, and "${@:-.}" rather than "$@", because eza
# 0.23.5 hangs indefinitely when invoked with no path argument on this machine
# -- `eza .` returns instantly, `eza` never returns. Passing an explicit `.`
# when no argument is given sidesteps it, and `ls some/dir` still works.
# Must be its own top-level statement, before the block below. oh-my-zsh
# aliases these names, and zsh refuses to define a function whose name is an
# existing alias -- a parse error, not a warning, which takes the rest of this
# file down with it. An `unalias` *inside* the `if` would be too late: zsh
# parses the whole if...fi as one unit before executing any of it.
unalias ls ll la lt 2>/dev/null

if _has eza; then
    _eza_opts=(--group-directories-first)
    ls() { eza $_eza_opts "${@:-.}" }
    ll() { eza $_eza_opts --long --git "${@:-.}" }
    la() { eza $_eza_opts --long --git --all "${@:-.}" }
    lt() { eza $_eza_opts --tree --level=2 "${@:-.}" }
fi
# }}}

# bat --- {{{
# `cat` is deliberately left alone; bat is for reading, cat is for piping.
if _has bat; then
    # Catppuccin ships with bat, so this matches vim and Ghostty. auto:system
    # reads the macOS appearance rather than sniffing terminal colors, which is
    # the same signal .vimrc uses.
    # BAT_THEME is deliberately NOT set: bat already defaults to auto, and the
    # older bat that delta bundles rejects the newer "auto:system" spelling with
    # `[bat warning]: Unknown theme`, silently falling back to a dark default.
    export BAT_THEME_DARK="Catppuccin Mocha"
    export BAT_THEME_LIGHT="Catppuccin Latte"
    export MANPAGER="sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'"
fi
# }}}

# fzf --- {{{
# One source, not three. This used to be sourced from the Homebrew share dir,
# from a ~/.fzf clone that vim-plug created, and again from ~/.fzf.zsh.
if _has fzf; then
    source <(fzf --zsh)

    export FZF_DEFAULT_COMMAND='rg --files --hidden'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    # ALT-C changes directory, so it needs directories -- it was listing files.
    _has fd && export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

    # Preview used to shell out to `highlight`, which was never installed, so
    # every preview silently fell through to plain cat.
    if _has bat; then
        _fzf_preview='bat --style=numbers --color=always {} 2>/dev/null || cat {} 2>/dev/null'
    else
        _fzf_preview='cat {} 2>/dev/null'
    fi

    export FZF_DEFAULT_OPTS="
    --preview '$_fzf_preview'
    --height 80%
    --border
    --color fg:#6272a4,bg:#282a36,hl:#ff79c6,fg+:#bd93f9,bg+:234,hl+:#ff79c6
    --color info:183,prompt:110,spinner:107,pointer:167,marker:215
    "
    export FZF_CTRL_R_OPTS='--preview-window hidden'
fi
# }}}

# atuin --- {{{
# Takes over C-r with a searchable, deduplicated, context-aware history.
# --disable-up-arrow keeps Up doing ordinary zsh prefix search.
if _has atuin; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi
# }}}

alias tl="tmux ls"
alias tn="_new_tmux_from_dir_name"
alias tc="_new_tmux_claude_workspace"
alias ta="tmux attach -d"

# A function, not an alias: in an alias the $(...) is expanded once, when the
# shell starts, in whatever directory that happened to be.
cdr() {
    local root
    # Checked separately: inside a .git directory rev-parse fails, and `cd ""`
    # quietly succeeds without going anywhere, so the failure would be silent.
    root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "cdr: not inside a git work tree" >&2
        return 1
    }
    cd "$root"
}

# Diff against the repo's actual default branch rather than assuming master.
gdmn() {
    git diff "$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo master)" --name-only
}

# delta --- {{{
# Pick delta's theme from the macOS appearance, matching .vimrc. Evaluated once
# per shell; after switching the system theme, new terminals pick it up, or run
# `retheme` in an existing one.
retheme() {
    # No leading "+": that form *appends* to the features set in .gitconfig,
    # so a light default plus a dark override would set both and delta exits
    # with "--light and --dark cannot be used together". Bare names replace.
    if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
        export DELTA_FEATURES="dark-mode"
    else
        export DELTA_FEATURES="light-mode"
    fi
}
_has delta && retheme
# }}}

_has lazygit && alias lg="lazygit"

bindkey "^Q" push-input

# fzf-tab --- {{{
if [ -d "$ZSH/custom/plugins/fzf-tab" ]; then
    # fzf-tab drives its own window, so the global --preview from
    # FZF_DEFAULT_OPTS would apply to completions it makes no sense for.
    zstyle ':fzf-tab:*' use-fzf-default-opts no
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:*' fzf-flags --height=60% --border

    # Preview what is being completed, per completion type.
    if _has eza; then
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza -1 --color=always $realpath'
    fi
    if _has bat; then
        zstyle ':fzf-tab:complete:*:*' fzf-preview \
            '[ -d $realpath ] && ls -1 $realpath || bat --color=always --style=numbers $realpath 2>/dev/null'
    fi
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview 'ps -p $word -o comm='
fi
# }}}

# git + fzf --- {{{
# Own statement, outside any block: oh-my-zsh's git plugin aliases both names,
# and defining a function over an existing alias is a parse error that takes
# the rest of this file with it. See the eza block above for the same problem.
unalias gco gsh 2>/dev/null

# gco: pick a branch, local or remote, most recently committed first.
gco() {
    local branch
    branch=$(git branch -a --sort=-committerdate \
        --format='%(refname:short)' 2>/dev/null \
        | grep -v '^origin/HEAD$' \
        | sed 's#^origin/##' | awk '!seen[$0]++' \
        | fzf --height 40% --preview 'git log --oneline --color=always -20 {}') || return
    [ -n "$branch" ] && git checkout "$branch"
}

# gsh: pick a commit and show it.
gsh() {
    local sha
    sha=$(git log --oneline --color=always -200 2>/dev/null \
        | fzf --ansi --height 60% --preview 'git show --color=always --stat {1}') || return
    [ -n "$sha" ] && git show "${sha%% *}"
}
# }}}

_execute_if_file_exists "$HOME"/.fzf_zsh
_execute_if_file_exists "$HOME"/.zshrc_local

# zsh-autosuggestions --- {{{
# Ghost-text completion from history as you type; -> or End accepts it.
if [ -e /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

    # Fall back to completion when history has nothing to offer.
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # Accept one word of the suggestion at a time.
    bindkey '^[f' forward-word
fi
# }}}

# zsh-syntax-highlighting --- {{{
# Must stay last in this file: it wraps every widget defined before it, and
# anything added afterwards goes unhighlighted.
if [ -e /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
# }}}
