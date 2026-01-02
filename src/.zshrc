# ==============================================================================
# tmux auto start
# ==============================================================================
# tmuxがインストールされていて、tmuxセッション外で、IDE内でない場合に自動起動
if command -v tmux &> /dev/null \
    && [[ -z "$TMUX" ]] \
    && [[ -z "$VSCODE_INJECTION" ]] \
    && [[ -z "$VSCODE_GIT_IPC_HANDLE" ]] \
    && [[ "$TERM_PROGRAM" != "vscode" ]] \
    && [[ "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]]; then
    # セッションの存在を確認してからexecで接続/作成
    if tmux has-session -t default 2>/dev/null; then
        exec tmux attach -t default
    else
        exec tmux new -s default
    fi
fi

# ==============================================================================
# PATH
# ==============================================================================
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# ==============================================================================
# Language
# ==============================================================================
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

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
stty erase ^H                # Ctrl+Hでバックスペース
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

# ==============================================================================
# Tools initialization
# ==============================================================================
# sheldon (zsh plugin manager)
type sheldon >/dev/null 2>&1 && eval "$(sheldon source)"

# starship (prompt)
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
type starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide (smart cd)
if [[ $- == *i* ]]; then
  type zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
fi

# ==============================================================================
# Google Cloud SDK
# ==============================================================================
export CLOUDSDK_PYTHON="$(which python3)"
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

# ==============================================================================
# Application-specific PATH
# ==============================================================================
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"
[ -d "$HOME/.cycloud/bin" ] && export PATH="$HOME/.cycloud/bin:$PATH"
[ -d "/opt/homebrew/opt/postgresql@17/bin" ] && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
