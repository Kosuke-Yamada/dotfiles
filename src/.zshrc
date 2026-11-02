# ==============================================================================
# PATH
# ==============================================================================
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH=$PATH:$HOME/.cycloud/bin
export PATH=$PATH:$HOME/.config/cycloud/bin

# ==============================================================================
# Language
# ==============================================================================
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# ==============================================================================
# Editor
# ==============================================================================
if type fresh >/dev/null 2>&1; then
    export EDITOR=fresh
    export VISUAL=fresh
fi

# ==============================================================================
# Browser
# ==============================================================================
# gcloud / gh などが URL を開くときの起動コマンド。
# 素の `open` だと、chrome-devtools-mcp 等が残した一時プロファイルの Chrome へ
# LaunchServices が URL を配送してしまい、ゲストモードのように見える。
# ラッパー経由で Chrome バイナリを直接呼び、プロファイルを固定する。
[ -x "$HOME/.local/bin/browser" ] && export BROWSER="$HOME/.local/bin/browser"

# ==============================================================================
# History
# ==============================================================================
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=1000000

setopt hist_ignore_dups      # 直前と同じコマンドは記録しない
setopt hist_ignore_all_dups  # 重複するコマンドは古い方を削除
setopt hist_ignore_space     # スペースで始まるコマンドは記録しない
setopt hist_reduce_blanks    # 余分な空白を削除して記録
setopt hist_save_no_dups     # ファイル保存時に重複を削除
setopt hist_no_store         # historyコマンド自体は記録しない
setopt hist_verify           # 履歴展開後、すぐに実行せず編集可能にする
setopt hist_expand           # 補完時に履歴を展開
setopt share_history         # 複数のzsh間で履歴を共有
setopt inc_append_history    # コマンド実行時に即座に履歴に追加
setopt extended_history      # 履歴にタイムスタンプを記録

# ==============================================================================
# Completion
# ==============================================================================
autoload -Uz compinit && compinit

# 大文字小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補をメニュー選択
zstyle ':completion:*:default' menu select=2

# 補完の詳細表示
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

setopt auto_menu             # Tabで補完候補を順に表示
setopt auto_param_slash      # ディレクトリ名の後に/を自動付加
setopt auto_param_keys       # カッコの対応などを自動補完
setopt complete_in_word      # 単語の途中でも補完
setopt list_types            # 補完候補にファイル種別を表示
setopt magic_equal_subst     # =以降も補完対象

# ==============================================================================
# Directory
# ==============================================================================
setopt auto_pushd            # cdでディレクトリスタックに追加
setopt pushd_ignore_dups     # 重複するディレクトリはスタックに追加しない
setopt mark_dirs             # ファイル名展開でディレクトリにマッチした場合/を付加

# ==============================================================================
# Keybind
# ==============================================================================
bindkey -e                   # Emacsキーバインド
[[ -t 0 ]] && stty erase ^H  # Ctrl+Hでバックスペース（tty接続時のみ）
bindkey "^[[3~" delete-char  # Deleteキーで削除

# ==============================================================================
# Misc
# ==============================================================================
setopt correct               # コマンドのスペルチェック
setopt interactive_comments  # コマンドラインでも#以降をコメントとして扱う
setopt no_beep               # ビープ音を鳴らさない
setopt nolistbeep            # 補完時のビープ音も鳴らさない
zle_highlight=('paste:none') # ペースト時のハイライトを無効化

# ==============================================================================
# External files
# ==============================================================================
[ -f "$HOME/.functions" ] && source "$HOME/.functions"
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"  # ローカル設定（Git管理外）

# ==============================================================================
# Tools initialization
# ==============================================================================
# 初期化コードを再利用し、タブを開くたびの外部プロセス起動を減らす。
# バイナリ・zshrc・関連設定の更新時は自動で作り直す。
_dotfiles_cached_init() {
    local tool=$1
    shift
    local binary=${commands[$tool]}
    [[ -n $binary ]] || return 0
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/zsh"
    local cache_file="$cache_dir/$tool.zsh"
    local cache_key="$binary ${(j: :)@}" dependency
    local -a dependencies=("$binary" "${(%):-%x}")
    local -A metadata
    case $tool in
        sheldon)
            dependencies+=(
                "${SHELDON_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/sheldon}/plugins.toml"
                "${SHELDON_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/sheldon}/plugins.lock"
            ) ;;
        starship) dependencies+=("$STARSHIP_CONFIG") ;;
    esac
    # zstat は zsh の組み込み。更新判定自体ではプロセスを起動しない。
    zmodload -F zsh/stat b:zstat || { eval "$("$binary" "$@")"; return; }
    for dependency in "${dependencies[@]}"; do
        metadata=()
        zstat -H metadata "$dependency" 2>/dev/null
        cache_key+="|$dependency:${metadata[device]}:${metadata[inode]}:${metadata[mtime]}:${metadata[ctime]}:${metadata[size]}"
    done
    local cached_key init_code temporary_file
    if [[ -r $cache_file ]]; then
        IFS= read -r cached_key < "$cache_file"
        if [[ $cached_key == "# $cache_key" ]]; then
            source "$cache_file"
            return
        fi
    fi
    init_code=$("$binary" "$@") || return $?
    # 読み取り専用環境ではキャッシュせず、通常どおり初期化する。
    if [[ -d $cache_dir ]] || (umask 077; command mkdir -p "$cache_dir") 2>/dev/null; then
        temporary_file="$cache_file.$$.$RANDOM"
        if (umask 077; print -r -- "# $cache_key"$'\n'"$init_code" > "$temporary_file") 2>/dev/null; then
            command mv -f "$temporary_file" "$cache_file" 2>/dev/null || command rm -f "$temporary_file"
        fi
    fi
    eval "$init_code"
}

# sheldon (zsh plugin manager)
_dotfiles_cached_init sheldon source

# Prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
# 外部プロセスの起動が遅い環境では、毎回 starship / git を待たない。
# 元の表示を使いたい場合は .zshrc.local に DOTFILES_PROMPT=starship を設定する。
if [[ ${DOTFILES_PROMPT:-native} == starship ]] && (( $+commands[starship] )); then
    autoload -Uz add-zsh-hook
    add-zsh-hook -d precmd _dotfiles_prompt_precmd
    add-zsh-hook -d preexec _dotfiles_prompt_preexec
    _dotfiles_cached_init starship init zsh
else
    zmodload zsh/datetime
    autoload -Uz add-zsh-hook

    _dotfiles_prompt_preexec() {
        _DOTFILES_COMMAND_STARTED=$EPOCHREALTIME
    }

    _dotfiles_prompt_precmd() {
        local command_status=$?
        local directory=$PWD git_directory head branch='' duration=''
        local marker elapsed
        # .git/HEAD を直接読む。通常のリポジトリ・worktree・submoduleに対応。
        # Gitの変更件数はここで調べず、必要なときに gst で確認する。
        while [[ -n $directory ]]; do
            if [[ -d $directory/.git ]]; then
                git_directory=$directory/.git
                break
            elif [[ -f $directory/.git ]]; then
                IFS= read -r marker < "$directory/.git"
                if [[ $marker == 'gitdir: '* ]]; then
                    git_directory=${marker#gitdir: }
                    [[ $git_directory == /* ]] || git_directory=$directory/$git_directory
                fi
                break
            fi
            [[ $directory == / ]] && break
            directory=${directory:h}
        done
        # 明示されたGitディレクトリも尊重する。
        [[ -n $GIT_DIR ]] && git_directory=$GIT_DIR
        if [[ -n $git_directory && -r $git_directory/HEAD ]]; then
            IFS= read -r head < "$git_directory/HEAD"
            if [[ $head == 'ref: refs/heads/'* ]]; then
                branch=${head#ref: refs/heads/}
            elif [[ -n $head && $head != *[^0-9a-f]* ]]; then
                branch=${head[1,7]}
            fi
        fi
        # パス・ブランチに含まれる % をプロンプトの書式として解釈しない。
        branch=${branch//\%/%%}
        [[ -n $branch ]] && branch="%F{magenta} $branch%f "
        if [[ -n $_DOTFILES_COMMAND_STARTED ]]; then
            elapsed=$(( EPOCHREALTIME - _DOTFILES_COMMAND_STARTED ))
            if (( elapsed >= 1 )); then
                printf -v duration '%.1fs' "$elapsed"
                duration="%F{yellow}$duration%f"
            fi
            unset _DOTFILES_COMMAND_STARTED
        fi
        local arrow='%F{green}❯%f'
        (( command_status )) && arrow='%F{red}❯%f'
        PROMPT=$'\n''%F{cyan}%~%f '"$branch$duration"$'\n'"$arrow "
        return 0
    }

    # source ~/.zshrc でも既存の Starship フックを残さない。
    add-zsh-hook -d precmd prompt_starship_precmd
    add-zsh-hook -d preexec prompt_starship_preexec
    add-zsh-hook preexec _dotfiles_prompt_preexec
    add-zsh-hook precmd _dotfiles_prompt_precmd
    unsetopt promptsubst
    PROMPT2='%F{yellow}…%f '
fi
RPROMPT=''

# zoxide (smart cd)
if [[ $- == *i* ]]; then
  _dotfiles_cached_init zoxide init zsh --cmd cd
fi
unfunction _dotfiles_cached_init

# ==============================================================================
# Google Cloud SDK
# ==============================================================================
if [ -x /opt/homebrew/bin/python3.14 ]; then
    export CLOUDSDK_PYTHON=/opt/homebrew/bin/python3.14
elif command -v python3 &>/dev/null; then
    export CLOUDSDK_PYTHON="$(command -v python3)"
fi
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

# ==============================================================================
# Application-specific PATH
# ==============================================================================
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"
[ -d "$HOME/.cycloud/bin" ] && export PATH="$HOME/.cycloud/bin:$PATH"
[ -d "/opt/homebrew/opt/postgresql@17/bin" ] && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/s26310/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# bun (mem-sync CLI)
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
