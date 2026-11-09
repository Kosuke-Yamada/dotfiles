# dotfiles

macOS / Linux 対応の開発環境セットアップ用 dotfiles リポジトリです。

## 概要

このリポジトリには以下の設定ファイルが含まれています:

| カテゴリ | ツール | バージョン | 導入 | 説明 |
|---------|--------|------------|------|------|
| シェル | [zsh](https://www.zsh.org/) | - | 2022-07 | メインシェル |
| プラグイン管理 | [sheldon](https://github.com/rossmacarthur/sheldon) | 0.8.5 | 2025-12 | zsh プラグインマネージャー |
| プロンプト | [starship](https://starship.rs/) | 1.24.1 | 2025-12 | カスタマイズ可能なプロンプト |
| ターミナル | [herdr](https://herdr.dev) | 0.7.5 | 2026-07 | AI エージェント対応ターミナルマルチプレクサ（デフォルト） |
| ターミナル | [ghostty](https://ghostty.org/) | 1.2.3 | 2025-12 | ターミナルエミュレータ (macOS) |
| ホットキー | [skhd](https://github.com/koekeishiya/skhd) | 0.3.9 | 2025-12 | ホットキーデーモン (macOS) |
| ウィンドウ管理 | [yabai](https://github.com/koekeishiya/yabai) | 7.1.16 | 2025-12 | タイリングウィンドウマネージャー (macOS) |
| Git | [git-delta](https://github.com/dandavison/delta) | 0.18.2 | 2025-12 | 差分表示の強化 |
| Git | [gitui](https://github.com/extrawurst/gitui) | nightly | 2025-12 | Git TUI クライアント |
| ファイル操作 | [eza](https://github.com/eza-community/eza) | 0.23.4 | 2025-12 | モダンな ls 代替 |
| ファイル操作 | [bat](https://github.com/sharkdp/bat) | 0.26.1 | 2025-12 | シンタックスハイライト付き cat |
| ファイル操作 | [fd](https://github.com/sharkdp/fd) | 10.3.0 | 2025-12 | 高速な find 代替 |
| 検索 | [ripgrep](https://github.com/BurntSushi/ripgrep) | 15.1.0 | 2025-12 | 高速な grep 代替 |
| ナビゲーション | [zoxide](https://github.com/ajeetdsouza/zoxide) | 0.9.8 | 2025-12 | スマートな cd |
| リポジトリ管理 | [ghq](https://github.com/x-motemen/ghq) | 1.8.0 | 2025-12 | Git リポジトリ管理 |
| 選択UI | [fzf](https://github.com/junegunn/fzf) | 0.67.0 | 2026-01 | インタラクティブフィルタリング |
| ビューア | [leaf](https://leaf.rivolink.mg/) | 1.28.0 | 2026-08 | GUI 風の操作感を持つターミナル Markdown ビューア |
| エディタ | [Fresh](https://getfresh.dev/) | 0.4.4 | 2026-07 | ゼロコンフィグなターミナルエディタ（VS Code 風の操作感） |
| エディタ | [Visual Studio Code](https://code.visualstudio.com/) | - | 2026-09 | GUI エディタ |
| AIエージェント | [Claude Code](https://claude.com/product/claude-code) | 2.1.206 | 2026-07 | ターミナル AI コーディングエージェント (macOS) |
| AIエージェント | [Codex](https://github.com/openai/codex) | 0.145.0 | 2026-07 | OpenAI のターミナル AI コーディングエージェント (macOS) |
| AIエージェントGUI | [T3 Code](https://t3.codes/) | 0.1.6 | 2026-11 | AI コーディングエージェントのデスクトップアプリ (macOS) |

## セットアップ

macOS では、OS に対応する Xcode Command Line Tools が必要です。未導入の場合は
`xcode-select --install` を実行して、インストール完了後に進めてください。
Xcode 本体を使用している場合は、対応版へ更新し、一度起動して追加コンポーネントの導入を完了してください。
Xcode / Command Line Tools の更新は、この Makefile では自動実行しません。

### 1. リポジトリのクローン

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
```

> クローン先は `~/dotfiles` に限らず任意のディレクトリで動作します（Makefile が `$(CURDIR)` を使用）。

### 2. セットアップの実行

```bash
cd ~/dotfiles
make        # make all と同じ。init の完了後に link を実行
exec zsh    # 新しい PATH とシェル設定を読み込む
```

Homebrew の配置は OS と CPU から自動判定します。選択した配置に Homebrew がなければ、
公式インストーラで導入します。

| 環境 | Homebrew の配置 |
|------|-----------------|
| Apple Silicon（M1 以降） | `/opt/homebrew` |
| Intel Mac | `/usr/local` |
| Linux | `/home/linuxbrew/.linuxbrew` |

Apple Silicon では、Intel 版 Homebrew が残っている場合や Rosetta 経由で `make` を実行した場合も、
ARM 版を選択します。既存の Intel 版は削除しません。make の各処理と、セットアップ後の `.zshrc` で
選択した Homebrew を PATH の先頭に追加します。

#### 利用可能なコマンド

| コマンド | 説明 |
|----------|------|
| `make all` | init と link を実行（フルセットアップ） |
| `make init` | Homebrew とパッケージをインストール |
| `make link` | シンボリックリンクを作成 |
| `make codex-skills` | Claude Code のスキルを Codex に共有 |
| `make codex-config` | Codex の共通設定を `~/.codex/config.toml` にマージ |
| `make t3-keybindings` | T3 Code のキー設定を配置（既存ファイルはバックアップ） |
| `make claude-mcp` | Claude Code の MCP サーバーを設定 |
| `make claude-mem` | claude-mem を Claude Code と Codex にインストール |
| `make vscode-extensions` | VS Code 拡張機能をインストール |
| `make help` | ヘルプを表示 |

#### `make init` の処理内容

1. **Homebrew の選択・インストール** - OS / CPU に合う配置を選択し、なければ導入
2. **パッケージのインストール** - Brewfile に定義されたツール群（macOS では Claude Code / Codex / T3 Code、共通で Node.js / uv / gh / jq を含む）。yabai / skhd の formula だけを明示的に信頼。Homebrew 外で導入済みのアプリ（手動導入や MDM 配布で `/Applications` にあるもの）は、取り込みに sudo が必要になるため cask をスキップして既存アプリを使う
3. **Sheldon プラグインのインストール** - zsh プラグインの取得
4. **Claude Code MCP サーバーの設定** - context7 / Playwright / serena / github
5. **claude-mem のインストール** - Claude Code と Codex へ共有メモリ機能を登録
6. **VS Code 拡張機能のインストール** - extensions.txt に基づき同期
7. **macOS 固有の設定** - skhd / yabai サービスの起動など

#### `make link` の処理内容

1. **シンボリックリンクの作成** - 設定ファイルをホームディレクトリにリンク
2. **既存ファイルのバックアップ** - 上書き前に自動バックアップ
3. **メニューバーの設定 (macOS)** - SwiftBar のプラグインディレクトリを設定し、ログイン時に起動する LaunchAgent を登録

#### セットアップ後の手動作業

メニューバーの AI 使用量表示（SwiftBar）は、各サービスへのログインが必要です。

```bash
claude            # Claude Code にログイン（CC の表示）
codex login       # Codex にログイン（~/.codex/auth.json を作成、CX の表示）
gh auth login     # GitHub にログイン（Copilot の表示と git の認証）
```

skhd / yabai / Karabiner-Elements / SwiftBar は初回起動時に macOS の権限許可（アクセシビリティなど）が必要です。

## ディレクトリ構成

```
dotfiles/
├── README.md
├── Makefile                  # セットアップ用 Makefile
├── Brewfile                  # Homebrew パッケージ定義
├── docs/                     # ドキュメント
└── src/                      # 設定ファイル本体
    ├── .aliases              # エイリアス定義
    ├── .functions            # カスタム関数定義
    ├── .gitconfig            # Git 設定
    ├── .zshrc                # zsh 設定
    ├── .zshrc.local.example  # ローカル設定のサンプル
    ├── .t3/userdata/         # T3 Code のキー設定（keybindings.json）
    ├── .local/bin/           # t3-toggle などのコマンド
    ├── .claude/              # Claude Code 設定（AI エージェント）
    │   ├── CLAUDE.md         # グローバル指示
    │   ├── settings.json     # 権限・プラグイン・MCP 等の設定
    │   ├── skills/           # アクティブなスキル（symlink 対象）
    │   │   ├── claude-md-creator/  # プロジェクトの CLAUDE.md を作成・登録するスキル
    │   │   └── related-work-survey/
    │   └── skills_catalog/   # 参考用スキルカタログ（symlink はしない）
    └── .config/
        ├── Code/             # VS Code 設定 (settings.json) と拡張機能リスト
        ├── fresh/            # Fresh 設定 (config.json)
        ├── ghostty/          # Ghostty 設定 (macOS)
        ├── herdr/            # herdr 設定
        ├── leaf/             # leaf 設定 (config.toml)
        ├── sheldon/          # Sheldon 設定
        ├── skhd/             # skhd 設定 (macOS)
        ├── starship/         # Starship 設定
        └── yabai/            # yabai 設定 (macOS)
```

### Fresh 設定

`src/.config/fresh/config.json` で管理しています。Fresh は「ゼロコンフィグ」が売りのターミナルエディタなので、この設定ファイルには**既定値から変更したい項目のみ**を記述しています（未記載のキーは既定値が使われます）。`make link` で `~/.config/fresh/config.json` にシンボリックリンクされます。

- インターフェース言語を日本語 (`ja`) に設定
- Nerd Font アイコンを有効化（HackGen Nerd Font を利用）
- インデントはスペース 2、保存時に末尾空白の除去と最終改行の付与を実行

全設定項目は `fresh --cmd config show`、アプリ内キーバインドは Help メニュー →「Keyboard Shortcuts」またはコマンドパレット（`Ctrl+T`）で確認できます。詳細は [docs/fresh.md](./docs/fresh.md) を参照してください。

### leaf 設定

`src/.config/leaf/config.toml` で管理しています。leaf は設定なしでも動作するターミナル Markdown ビューアなので、この設定ファイルには**既定値から変更したい項目のみ**を記述しています。`make link` で `~/.config/leaf/config.toml` にシンボリックリンクされます。

- 外部エディタ（`Ctrl+E`）に Fresh を使用: `editor = "fresh {$path}:{$line}"`
  - `{$path}` / `{$line}` は leaf が展開するプレースホルダで、表示中の先頭行に対応する位置で Fresh が開きます
  - 優先順位は `--editor` フラグ > `LEAF_EDITOR` > この設定 > `nano`

既定値付きのフルテンプレート（全設定項目とコメント）は `leaf --config` で生成・確認できます。アプリ内キーバインドは leaf 起動中に `?` で表示できます。

> leaf は Homebrew（`leaf-markdown-viewer`）で管理しているため、更新は `brew upgrade` を使用します。自己更新機能の `leaf --update` は使いません（Homebrew の管理外にバイナリが分岐するため）。

### T3 Code 設定

macOS では `make init` の Homebrew Bundle 処理で `t3-code` cask をインストールします。
本体だけをインストールする場合は `brew install --cask t3-code` を実行します。

`make link` または `make t3-keybindings` で、`src/.t3/userdata/keybindings.json` を
`~/.t3/userdata/keybindings.json` にリンクします。既存の通常ファイルは同じディレクトリへ
日時付きでバックアップします。履歴・認証情報など、ほかの `.t3` 配下のデータは管理対象にしません。
キー設定が反映されない場合は T3 Code を再起動してください。

`make link` で配置される `t3-toggle` は、T3 Code が最前面なら非表示にし、それ以外なら
前面に表示します。未起動なら起動します。macOS の skhd 設定では `Ctrl+T` に割り当てています。
このグローバルキーは、zsh の文字入れ替えや Fresh のコマンドパレットなど、ほかのアプリの `Ctrl+T` より優先されます。

| キー | 操作 |
|------|------|
| `Ctrl+T` | T3 Code の前面表示／非表示（グローバル、macOS） |
| `Cmd+T` | 通常の新規チャット（必要に応じてプロジェクト選択） |
| `Cmd+N` | 現在のプロジェクトで新規チャット |
| `Cmd+E` | プロジェクトなしで新規チャット |

上記の新規チャット操作は内蔵ターミナルにフォーカスがないときに有効です。
ターミナル内の `Cmd+N` は新規ターミナル作成です。`Cmd+T` は右パネルの新規タブより
新規チャット作成を優先します。`Cmd+C` のコピー操作は変更していません。

### VS Code 拡張機能

`src/.config/Code/extensions.txt` で管理しています。`make init` または `make vscode-extensions` でインストールされます。

#### 拡張機能の更新方法

```bash
# 現在の拡張機能リストを更新
code --list-extensions | sort > ~/dotfiles/src/.config/Code/extensions.txt
```

#### 主な拡張機能カテゴリ

| カテゴリ | 主な拡張機能 |
|----------|--------------|
| Python | ms-python.python, charliermarsh.ruff, ms-toolsai.jupyter |
| JavaScript/TypeScript | dbaeumer.vscode-eslint, esbenp.prettier-vscode |
| Vue | vue.volar |
| CSS | bradlc.vscode-tailwindcss |
| Git | eamodio.gitlens, mhutchie.git-graph |
| AI | anthropic.claude-code |

### AI エージェント設定（Claude Code / Codex）

[agent-config](https://github.com/Kosuke-Yamada/agent-config) から統合した AI エージェント設定を管理しています。

#### Claude Code (`src/.claude/`)

`make link` で以下がホームディレクトリにシンボリックリンクされます。

| 対象 | リンク先 | 内容 |
|------|----------|------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | 全セッション共通のグローバル指示（日本語環境・開発方針など） |
| `settings.json` | `~/.claude/settings.json` | 権限（allow/deny/ask）、プラグイン、MCP、言語設定など |
| `skills/*` | `~/.claude/skills/<name>` | 各スキルディレクトリ |

MCP サーバー（context7 / Playwright / serena / github）は `make claude-mcp` で登録されます。GitHub MCP には `GITHUB_TOKEN` 環境変数が必要です（`~/.zshrc.local` に設定）。

#### Codex (`src/.codex/`)

`make codex-config`（`make link` にも含まれる）で共通設定を `~/.codex/config.toml` にマージします。
端末固有のプロジェクト・プラグイン設定は保持します。反映後は Codex CLI を再起動してください。

下部のステータス行には、モデル、5 時間・週間の使用上限、現在のスレッドの消費 credits・推定金額（USD）、スレッド名、プロジェクト、ブランチを表示します。
`thread-credits` / `estimated-thread-cost` は Enterprise ワークスペースで料金データが提供される場合のみ表示され、データがない場合は省略されます。購入済み credits の残高や月間合計ではありません。

#### claude-mem（Claude Code / Codex 共通）

`make init` または `make claude-mem` は公式インストーラを実行し、claude-mem を
Claude Code (`claude-code`) と Codex (`codex-cli`) の両方へ明示的に登録した後、
共有 worker を起動します。両者は `~/.claude-mem/` のランタイムとメモリデータを
共有します。再実行時は最新版へ更新されます。

#### スキル

| スキル | 呼び出し | 内容 |
|--------|----------|------|
| `claude-md-creator` | `/claude-md-creator` | プロジェクトの `./CLAUDE.md` を作成・登録する。スタック別テンプレート（Python / React+FastAPI / Streamlit）から選ぶか、いずれにも当てはまらない場合はその場で推奨 CLAUDE.md を日本語で生成する。登録前に内容を表示して確認。テンプレートは `skills/claude-md-creator/templates/` に同梱 |
| `related-work-survey` | `/related-work-survey` | 研究テーマの関連研究を国際会議・arXiv からサーベイし Markdown を生成 |

`skills_catalog/` は参考用のスキルカタログで、シンボリックリンクはされません。

Claude Code のアクティブなスキルは、`make link` または `make codex-skills` で
`~/.codex/skills/<name>` にも共有リンクされます。Codex 固有のシステムスキルや
プラグインスキルには触れず、`src/.claude/skills/` で管理するスキルだけが対象です。

## 注意事項

### Xcode が古く、パッケージのインストールに失敗する場合

`Your Xcode (...) ... is too outdated` が出た場合は、App Store から Xcode を
エラーに示された対応版へ更新してください。更新後に Xcode を一度起動し、
追加コンポーネントの導入を完了してから `make` を再実行します。
Command Line Tools の更新を求められた場合は、システム設定の「ソフトウェアアップデート」で更新してください。

この共通エラーで多数の `Installing ... has failed!` が続く場合は、
先に開発ツールの問題を解消します。再実行時に導入済みのパッケージを削除する必要はありません。
必要な開発ツールは [Homebrew のインストール要件](https://docs.brew.sh/Installation)を参照してください。

### M1 なのに Homebrew が Intel と表示する場合

更新済みのリポジトリで `make` を実行し、完了後に `exec zsh` でシェルを読み直してください。
`which brew` が `/opt/homebrew/bin/brew`、`brew --prefix` が `/opt/homebrew` を
示すことを確認します。make が途中で失敗して `make link` まで進まなかった場合は、
現在のターミナルで `eval "$(/opt/homebrew/bin/brew shellenv)"` を実行すると ARM 版を選択できます
（ARM 版 Homebrew の導入完了後のみ）。

Homebrew の配置と移行については [公式のトラブルシューティング](https://docs.brew.sh/Common-Issues#multiple-homebrew-installations)を参照してください。

### macOS での skhd / yabai 権限設定

skhd と yabai を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `$(brew --prefix)/bin/skhd` と `$(brew --prefix)/bin/yabai` の実際のパスを追加して有効化（Apple Silicon は `/opt/homebrew/bin`、Intel Mac は `/usr/local/bin`）
3. 以下のコマンドでサービスを再起動:
   ```bash
   skhd --restart-service
   yabai --restart-service
   ```

### 既存ファイルのバックアップ

セットアップ時に既存の設定ファイル（シンボリックリンクでないもの）は、`~/.backup/dotfiles/` に自動でバックアップされます。

### Linux での注意

- ghostty、skhd、yabai は macOS 専用のため、Linux ではインストールされません
- フォント（HackGen）も macOS 専用です
- この Brewfile の Claude Code / Codex / T3 Code は macOS 専用の cask として登録しています。Linux では各公式インストーラを利用してください。

### zsh プラグイン

sheldon で管理している zsh プラグイン:

- **zsh-autosuggestions** - コマンド入力補完の提案
- **zsh-syntax-highlighting** - コマンドのシンタックスハイライト
- **zsh-completions** - 追加の補完定義

sheldon・starship・zoxide の初期化コードは `${XDG_CACHE_HOME:-~/.cache}/dotfiles/zsh/` にキャッシュします。ツール本体・`.zshrc`・関連設定を更新すると自動で再生成されます。手動で作り直す場合は、このディレクトリ内の `.zsh` ファイルを削除して新しいシェルを開いてください。キャッシュに書き込めない環境でも通常の初期化に戻ります。

標準のプロンプトは zsh の組み込み機能だけで動きます。ディレクトリ・Git ブランチ（worktree を含む）・終了状態の色・1秒以上の実行時間を表示し、Enter のたびに Starship や Git の外部プロセスを起動しません。Git の変更件数は `gst` で確認してください。

Starship の表示を使う場合は `~/.zshrc.local` に `DOTFILES_PROMPT=starship` を設定し、新しいシェルを開いてください。Starship でも右プロンプト用の追加プロセス起動は省きます。標準の表示に戻すには、この設定を削除して `source ~/.zshrc` を実行します。

## キーバインド

詳細なキーバインドは [docs/](./docs/) を参照してください。

| ツール | キー | 説明 |
|--------|------|------|
| zsh | `Ctrl+]` | ghq リポジトリを fzf で検索 |
| zsh | `Ctrl+R` | コマンド履歴を fzf で検索 |
| herdr | `Ctrl+B` | Prefix キー（続けてキーを押す） |
| Fresh | `Ctrl+P` | クイックオープン（ファイル / コマンド / バッファ / 行） |
| Fresh | `Ctrl+T` | コマンドパレット |
| leaf | `Ctrl+E` | 表示中のファイルを外部エディタ (Fresh) で開く |
| leaf | `Ctrl+F` | ドキュメント内を検索 |
| leaf | `Ctrl+W` | ウォッチモード（変更時の自動リロード）の切替 |
| ghostty | `Ctrl+G` | Quick Terminal の表示/非表示 |
| T3 Code + skhd | `Ctrl+T` | T3 Code の前面表示／非表示（ほかのアプリの同じキーより優先） |
| T3 Code | `Cmd+T` / `Cmd+N` / `Cmd+E` | 通常／現在のプロジェクト／プロジェクトなしで新規チャット |
| skhd + yabai | `Alt+Cmd+←/→/↑/↓` | ウィンドウを画面の左/右/上/下半分に配置 |

## ドキュメント

- [エイリアス一覧](./docs/aliases.md)
- [カスタム関数一覧](./docs/functions.md)
- [Git コマンド](./docs/git.md)
- [Fresh エディタ](./docs/fresh.md)
- [herdr キーバインド](./docs/herdr.md)
- [skhd & yabai キーバインド](./docs/skhd-yabai.md)

## ライセンス

MIT
