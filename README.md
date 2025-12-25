# dotfiles

macOS / Linux 対応の開発環境セットアップ用 dotfiles リポジトリです。

## 概要

このリポジトリには以下の設定ファイルが含まれています:

| カテゴリ | ツール | バージョン | 説明 |
|---------|--------|------------|------|
| シェル | [zsh](https://www.zsh.org/) | - | メインシェル |
| プラグイン管理 | [sheldon](https://github.com/rossmacarthur/sheldon) | 0.8.5 | zsh プラグインマネージャー |
| プロンプト | [starship](https://starship.rs/) | 1.24.1 | カスタマイズ可能なプロンプト |
| ターミナル | [zellij](https://zellij.dev/) | 0.43.1 | ターミナルマルチプレクサ |
| ターミナル | [ghostty](https://ghostty.org/) | 1.2.3 | ターミナルエミュレータ (macOS) |
| ホットキー | [skhd](https://github.com/koekeishiya/skhd) | 0.3.9 | ホットキーデーモン (macOS) |
| ウィンドウ管理 | [yabai](https://github.com/koekeishiya/yabai) | 7.1.16 | タイリングウィンドウマネージャー (macOS) |
| Git | [git-delta](https://github.com/dandavison/delta) | 0.18.2 | 差分表示の強化 |
| Git | [gitui](https://github.com/extrawurst/gitui) | nightly | Git TUI クライアント |
| エディタ | [nano](https://www.nano-editor.org/) | - | Git デフォルトエディタ |
| ファイル操作 | [eza](https://github.com/eza-community/eza) | 0.23.4 | モダンな ls 代替 |
| ファイル操作 | [bat](https://github.com/sharkdp/bat) | 0.26.1 | シンタックスハイライト付き cat |
| ファイル操作 | [fd](https://github.com/sharkdp/fd) | 10.3.0 | 高速な find 代替 |
| 検索 | [ripgrep](https://github.com/BurntSushi/ripgrep) | 15.1.0 | 高速な grep 代替 |
| ナビゲーション | [zoxide](https://github.com/ajeetdsouza/zoxide) | 0.9.8 | スマートな cd |
| リポジトリ管理 | [ghq](https://github.com/x-motemen/ghq) | 1.8.0 | Git リポジトリ管理 |
| 選択UI | [peco](https://github.com/peco/peco) | 0.5.11 | インタラクティブフィルタリング |

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
```

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
| `make help` | ヘルプを表示 |

#### `make init` の処理内容

1. **Homebrew のインストール** - 未インストールの場合のみ
2. **パッケージのインストール** - Brewfile に定義されたツール群
3. **Sheldon プラグインのインストール** - zsh プラグインの取得
4. **macOS 固有の設定** - skhd / yabai サービスの起動など

#### `make link` の処理内容

1. **シンボリックリンクの作成** - 設定ファイルをホームディレクトリにリンク
2. **既存ファイルのバックアップ** - 上書き前に自動バックアップ

## ディレクトリ構成

```
dotfiles/
├── README.md
├── Makefile              # セットアップ用 Makefile
├── Brewfile              # Homebrew パッケージ定義
├── docs/                 # ドキュメント
└── src/                  # 設定ファイル本体
    ├── .aliases          # エイリアス定義
    ├── .functions        # カスタム関数定義
    ├── .gitconfig        # Git 設定
    ├── .nanorc           # nano 設定
    ├── .zshrc            # zsh 設定
    └── .config/
        ├── ghostty/      # Ghostty 設定 (macOS)
        ├── sheldon/      # Sheldon 設定
        ├── skhd/         # skhd 設定 (macOS)
        ├── starship/     # Starship 設定
        ├── yabai/        # yabai 設定 (macOS)
        └── zellij/       # Zellij 設定
```

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

### zsh プラグイン

sheldon で管理している zsh プラグイン:

- **zsh-autosuggestions** - コマンド入力補完の提案
- **zsh-syntax-highlighting** - コマンドのシンタックスハイライト
- **zsh-completions** - 追加の補完定義

## キーバインド

詳細なキーバインドは [docs/](./docs/) を参照してください。

| ツール | キー | 説明 |
|--------|------|------|
| zsh | `Ctrl+]` | ghq リポジトリを peco で検索 |
| zsh | `Ctrl+R` | コマンド履歴を peco で検索 |
| ghostty | `Ctrl+G` | Quick Terminal の表示/非表示 |
| skhd | `Alt+Return` | Ghostty を起動 |
| skhd | `Alt+B` | Arc ブラウザを起動 |
| skhd | `Alt+E` | Finder を起動 |
| skhd + yabai | `Alt+Cmd+←/→/↑/↓` | ウィンドウを画面の左/右/上/下半分に配置 |

## ドキュメント

- [エイリアス一覧](./docs/aliases.md)
- [カスタム関数一覧](./docs/functions.md)
- [Git コマンド](./docs/git.md)
- [eza コマンド](./docs/eza.md)
- [Zellij キーバインド](./docs/zellij.md)
- [skhd キーバインド](./docs/skhd.md)
- [yabai 設定](./docs/yabai.md)

## ライセンス

MIT
