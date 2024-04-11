export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/miniconda3/bin:$PATH

# history
export HISTSIZE=1000
export SAVEHIST=1000000
export HISTFILE=$HOME/.zsh_history
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store
setopt hist_expand
setopt inc_append_history

# Complement
autoload -U compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=2
setopt auto_param_slash
setopt auto_pushd
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt interactive_comments
setopt magic_equal_subst
setopt complete_in_word
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

# highlight
zle_highlight=('paste:none')

# nobeep
setopt no_beep
setopt nolistbeep


export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

bindkey -e

setopt pushd_ignore_dups
setopt correct

stty erase ^H
bindkey "^[[3~" delete-char

[ -f $HOME/.functions ] && source $HOME/.functions
[ -f $HOME/.aliases ] && source $HOME/.aliases

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-rust \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node

zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zsh-users/zsh-syntax-highlighting \
    blockf \
        zsh-users/zsh-completions \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

# load pure
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure
zstyle :prompt:pure:git:branch color cyan
zstyle :prompt:pure:git:dirty color magenta
zstyle :prompt:pure:host color magenta
zstyle :prompt:pure:prompt:success color green
zstyle :prompt:pure:user color green
zstyle :prompt:pure:virtualenv color yellow
### End of Zinit's installer chunk

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/s26310/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/s26310/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/s26310/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/s26310/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
