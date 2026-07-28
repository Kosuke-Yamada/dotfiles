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
| ターミナル | [tmux](https://github.com/tmux/tmux) | - | 2026-01 | ターミナルマルチプレクサ（設定ファイルのみ） |
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
| エディタ | [Fresh](https://getfresh.dev/) | 0.4.4 | 2026-07 | ゼロコンフィグなターミナルエディタ（VS Code 風の操作感） |
| エディタ | [Cursor](https://cursor.com/) | - | 2026-01 | AI 搭載エディタ (VS Code fork) |
| AIエージェント | [Claude Code](https://claude.com/product/claude-code) | 2.1.206 | 2026-07 | ターミナル AI コーディングエージェント (macOS) |
| AIエージェント | [Codex](https://github.com/openai/codex) | 0.145.0 | 2026-07 | OpenAI のターミナル AI コーディングエージェント (macOS) |

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
```

> クローン先は `~/dotfiles` に限らず任意のディレクトリで動作します（Makefile が `$(CURDIR)` を使用）。

### 2. セットアップの実行

```bash
cd ~/dotfiles
make all    # または make init && make link
```

#### 利用可能なコマンド

| コマンド | 説明 |
|----------|------|
| `make all` | init と link を実行（フルセットアップ） |
| `make init` | Homebrew とパッケージをインストール |
| `make link` | シンボリックリンクを作成 |
| `make claude-mcp` | Claude Code の MCP サーバーを設定 |
| `make cursor-extensions` | Cursor 拡張機能をインストール |
| `make cursor-agent-permissions` | cursor-agent の permissions をマージ |
| `make help` | ヘルプを表示 |

#### `make init` の処理内容

1. **Homebrew のインストール** - 未インストールの場合のみ
2. **パッケージのインストール** - Brewfile に定義されたツール群（Claude Code / Codex を含む）
3. **Sheldon プラグインのインストール** - zsh プラグインの取得
4. **Claude Code MCP サーバーの設定** - context7 / Playwright / serena / github
5. **Cursor 拡張機能のインストール** - extensions.txt に基づき同期
6. **cursor-agent permissions のマージ** - Claude Code の settings.json を cli-config.json に反映
7. **macOS 固有の設定** - skhd / yabai サービスの起動など

#### `make link` の処理内容

1. **シンボリックリンクの作成** - 設定ファイルをホームディレクトリにリンク
2. **既存ファイルのバックアップ** - 上書き前に自動バックアップ

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
    ├── .tmux.conf            # tmux 設定
    ├── .zshrc                # zsh 設定
    ├── .zshrc.local.example  # ローカル設定のサンプル
    ├── .claude/              # Claude Code 設定（AI エージェント）
    │   ├── CLAUDE.md         # グローバル指示
    │   ├── settings.json     # 権限・プラグイン・MCP 等の設定
    │   ├── skills/           # アクティブなスキル（symlink 対象）
    │   │   ├── claude-md-creator/  # プロジェクトの CLAUDE.md を作成・登録するスキル
    │   │   └── related-work-survey/
    │   └── skills_catalog/   # 参考用スキルカタログ（symlink はしない）
    ├── .cursor/              # cursor-agent 設定
    │   ├── rules/            # グローバルルール (*.mdc)
    │   └── merge_permissions.py  # settings.json → cli-config.json 変換
    └── .config/
        ├── Code/             # VS Code 設定 (settings.json)
        ├── cursor/           # Cursor 拡張機能リスト
        ├── fresh/            # Fresh 設定 (config.json)
        ├── ghostty/          # Ghostty 設定 (macOS)
        ├── herdr/            # herdr 設定
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

### Cursor 拡張機能

`src/.config/cursor/extensions.txt` で管理しています。`make init` または `make cursor-extensions` でインストールされます。

#### 拡張機能の更新方法

```bash
# 現在の拡張機能リストを更新
cursor --list-extensions | sort > ~/dotfiles/src/.config/cursor/extensions.txt
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

### AI エージェント設定（Claude Code / cursor-agent）

[agent-config](https://github.com/Kosuke-Yamada/agent-config) から統合した AI エージェント設定を管理しています。

#### Claude Code (`src/.claude/`)

`make link` で以下がホームディレクトリにシンボリックリンクされます。

| 対象 | リンク先 | 内容 |
|------|----------|------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | 全セッション共通のグローバル指示（日本語環境・開発方針など） |
| `settings.json` | `~/.claude/settings.json` | 権限（allow/deny/ask）、プラグイン、MCP、言語設定など |
| `skills/*` | `~/.claude/skills/<name>` | 各スキルディレクトリ |

MCP サーバー（context7 / Playwright / serena / github）は `make claude-mcp` で登録されます。GitHub MCP には `GITHUB_TOKEN` 環境変数が必要です（`~/.zshrc.local` に設定）。

#### スキル

| スキル | 呼び出し | 内容 |
|--------|----------|------|
| `claude-md-creator` | `/claude-md-creator` | プロジェクトの `./CLAUDE.md` を作成・登録する。スタック別テンプレート（Python / React+FastAPI / Streamlit）から選ぶか、いずれにも当てはまらない場合はその場で推奨 CLAUDE.md を日本語で生成する。登録前に内容を表示して確認。テンプレートは `skills/claude-md-creator/templates/` に同梱 |
| `related-work-survey` | `/related-work-survey` | 研究テーマの関連研究を国際会議・arXiv からサーベイし Markdown を生成 |

`skills_catalog/` は参考用のスキルカタログで、シンボリックリンクはされません。

#### cursor-agent (`src/.cursor/`)

- `rules/*.mdc` → `~/.cursor/rules/` にリンク（全プロジェクト共通のグローバルルール）
- `make link` で claude-code のスキルを `~/.cursor/skills/` にも共有リンク
- `make cursor-agent-permissions` で Claude Code の `settings.json` の permissions を cursor-agent の `~/.cursor/cli-config.json` にマージ（`Bash()` → `Shell()`、`Write()` → `Edit()` に変換）。cursor-agent を一度起動して `cli-config.json` を生成してから実行してください。

## 注意事項

### macOS での skhd / yabai 権限設定

skhd と yabai を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `/opt/homebrew/bin/skhd` と `/opt/homebrew/bin/yabai` を追加して有効化
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
- Claude Code / Codex は Homebrew cask でのみ提供されるため、Linux ではインストールされません（Linux では各公式インストーラを利用してください）

### zsh プラグイン

sheldon で管理している zsh プラグイン:

- **zsh-autosuggestions** - コマンド入力補完の提案
- **zsh-syntax-highlighting** - コマンドのシンタックスハイライト
- **zsh-completions** - 追加の補完定義

## キーバインド

詳細なキーバインドは [docs/](./docs/) を参照してください。

| ツール | キー | 説明 |
|--------|------|------|
| zsh | `Ctrl+]` | ghq リポジトリを fzf で検索 |
| zsh | `Ctrl+R` | コマンド履歴を fzf で検索 |
| herdr | `Ctrl+B` | Prefix キー（続けてキーを押す） |
| Fresh | `Ctrl+P` | クイックオープン（ファイル / コマンド / バッファ / 行） |
| Fresh | `Ctrl+T` | コマンドパレット |
| ghostty | `Ctrl+G` | Quick Terminal の表示/非表示 |
| skhd + yabai | `Alt+Cmd+←/→/↑/↓` | ウィンドウを画面の左/右/上/下半分に配置 |

## ドキュメント

- [エイリアス一覧](./docs/aliases.md)
- [カスタム関数一覧](./docs/functions.md)
- [Git コマンド](./docs/git.md)
- [Fresh エディタ](./docs/fresh.md)
- [herdr キーバインド](./docs/herdr.md)
- [tmux キーバインド](./docs/tmux.md)
- [skhd & yabai キーバインド](./docs/skhd-yabai.md)

## ライセンス

MIT
