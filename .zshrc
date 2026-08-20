# zmodload zsh/zprof

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"
# ZSH_THEME="gentoo"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
#  COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# plugins=(git sublime npm node brew jsontools zsh-syntax-highlighting mvn jira)
plugins=(git sublime npm node brew jsontools mvn jira)

# ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets cursor line pattern root)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

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

ssh-add ~/.ssh/id_rsa 2>/dev/null
HOMEBREW_BIN_DIR=/usr/local/bin:/usr/local/sbin
NODE_MODULES=./node_modules/.bin
LOCAL_BIN_DIR=$HOME/.local/bin:$HOME/local/bin
PLATFORM=$(uname)

if [[ "$PLATFORM" == "Darwin" ]]; then
    source $(brew --prefix)/etc/profile.d/z.sh
    export PATH=$HOMEBREW_BIN_DIR:$PATH
    export NVM_DIR=~/.nvm
    export NVM_PREFIX=$(brew --prefix nvm)

    # see http://www.growingwiththeweb.com/2018/01/slow-nvm-init.html
    # Defer initialization of nvm until nvm, node or a node-dependent command is
    # run. Ensure this block is only run once if .bashrc gets sourced multiple times
    # by checking whether __init_nvm is a function.
    if [ -s "$NVM_PREFIX/nvm.sh" ] && [ ! "$(whence -w __init_nvm)" = function ]; then
      [ -s "$NVM_PREFIX/bash_completion" ] && . "$NVM_PREFIX/bash_completion"
      declare -a __node_commands=('nvm' 'node' 'npm' 'yarn' 'gulp' 'grunt' 'webpack')
      function __init_nvm() {
        for i in "${__node_commands[@]}"; do unalias $i; done
        source "$NVM_PREFIX"/nvm.sh
        unset __node_commands
        unset -f __init_nvm
      }
      for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
    fi
else
    echo Unknown platform $PLATFORM
fi

export PATH=$LOCAL_BIN_DIR:$PATH:$NODE_MODULES

export EDITOR="vim"

alias tl="tmux ls"
alias tn="_new_tmux_from_dir_name"
alias ta="tmux attach -d"
alias cdr="cd $(ls .git 2>&1 1>/dev/null && git rev-parse --show-toplevel)"
alias gdmn="git diff master --name-only"

bindkey "^Q" push-input

# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
    source /usr/local/opt/fzf/shell/key-bindings.zsh
    source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf via local installation
if [ -e ~/.fzf ]; then
    _append_to_path ~/.fzf/bin
    source ~/.fzf/shell/key-bindings.zsh
    source ~/.fzf/shell/completion.zsh
fi

# fzf + rg configuration
if _has fzf && _has rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='
    --preview "highlight -O ansi -l {} 2>/dev/null || cat 2>/dev/null {} || echo \"No preview\""
    --height 80%
    --color fg:#6272a4,bg:#282a36,hl:#ff79c6,fg+:#bd93f9,bg+:234,hl+:#ff79c6
    --color info:183,prompt:110,spinner:107,pointer:167,marker:215
    '
fi

    # --color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33
    # --color info:136,prompt:136,pointer:234,marker:234,spinner:136

_execute_if_file_exists "$HOME"/.fzf_zsh
_execute_if_file_exists "$HOME"/.zshrc_local

# zprof

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
