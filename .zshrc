export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
export PATH="$HOME/.local/bin:$PATH"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

alias vim=nvim
alias vi=nvim

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="robbyrussell"

plugins=(git sublime npm node brew jsontools)

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

if [[ "$(uname)" == "Darwin" ]]; then
    source $(brew --prefix)/etc/profile.d/z.sh
fi

export PATH="$PATH:$NODE_MODULES"

export EDITOR="vim"

alias tl="tmux ls"
alias tn="_new_tmux_from_dir_name"
alias ta="tmux attach -d"
alias cdr="cd $(ls .git 2>&1 1>/dev/null && git rev-parse --show-toplevel)"
alias gdmn="git diff master --name-only"

bindkey "^Q" push-input

# fzf via Homebrew
if [ -e /opt/homebrew/opt/fzf/shell/completion.zsh ]; then
    source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    source /opt/homebrew/opt/fzf/shell/completion.zsh
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

_execute_if_file_exists "$HOME"/.fzf_zsh
_execute_if_file_exists "$HOME"/.zshrc_local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
