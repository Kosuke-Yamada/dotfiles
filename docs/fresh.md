# Fresh エディタ

[Fresh](https://getfresh.dev/) は「ゼロコンフィグ」を掲げるモダンなターミナルテキストエディタです。VS Code / Sublime Text 風の操作感（マウス対応・メニューバー・コマンドパレット・マルチカーソル・LSP）をそのままターミナルに持ち込んでおり、モードや特殊なキー操作を覚える必要がありません。設定ファイルは `src/.config/fresh/config.json`。

## インストール

Homebrew で管理しています（formula 名は `fresh-editor`、コマンド名は `fresh`）。

```bash
brew install fresh-editor   # または make init（Brewfile 経由）
```

`make link` で `src/.config/fresh/config.json` が `~/.config/fresh/config.json` にシンボリックリンクされます。`src/.zshrc` で `EDITOR` / `VISUAL` を `fresh` に設定しています。

## 設定

Fresh は既定値だけで十分使えるため、`config.json` には**既定値から変えたい項目のみ**を記述しています（JSONC 形式でコメント可）。

| 設定 | 値 | 説明 |
|------|----|------|
| `locale` | `ja` | インターフェース言語を日本語に |
| `editor.nerd_font_icons` | `true` | Nerd Font アイコンを使用（HackGen Nerd Font を利用） |
| `editor.use_tabs` / `tab_size` | `false` / `2` | インデントはスペース 2 |
| `editor.trim_trailing_whitespace_on_save` | `true` | 保存時に行末の空白を除去 |
| `editor.ensure_final_newline_on_save` | `true` | 保存時にファイル末尾へ改行を付与 |
| `clipboard.use_osc52` / `use_system_clipboard` | `true` | OSC52 とシステムクリップボード連携（SSH 越しでもコピー可） |

- 全設定項目とその既定値は `fresh --cmd config show`、保存先は `fresh --cmd config paths` で確認できます。
- 設定ファイルの保存先:
  - 設定: `~/.config/fresh/`（`config.json` / `themes/` / `grammars/` / `plugins/`）
  - データ: `~/Library/Application Support/fresh/`（ワークスペース・復旧データ）
  - ログ: `~/.local/state/fresh/logs/`

> `~/.config/fresh/` 配下の `tsconfig.json` と `types/` は、TypeScript 製プラグイン／`init.ts` 用に Fresh が自動生成するファイルです。dotfiles では管理せず、`config.json` のみをリンクしています。

### テーマの変更

既定テーマは `high-contrast` です。変更するにはメニューバーまたはコマンドパレットの「Select Theme」から選ぶか、`config.json` に `"theme": "<name>"` を追記します。組み込みテーマ: `dark` / `light` / `dracula` / `high-contrast` / `nord` / `nostalgia` / `solarized-dark` / `terminal`。

## CLI コマンド

シェルから叩く CLI コマンドの一覧です（`fresh [オプション] [ファイル...]`）。

### 起動・ファイルを開く

| コマンド | 説明 |
|---|---|
| `fresh` | 前回のワークスペースを復元して起動 |
| `fresh <file>` | ファイルを開く |
| `fresh 'file:10'` / `'file:10:5'` | 10 行目 / 10 行 5 列で開く |
| `fresh 'file:10-20'` | 10〜20 行目を選択して開く |
| `fresh 'file:10@"msg"'` | 10 行目で開き Markdown ポップアップを表示 |
| `fresh --stdin` / `fresh -` | 標準入力から読み込む |

> 位置指定はシェル展開を避けるためシングルクォート推奨。

### `--cmd` ユーティリティ

| コマンド | 説明 |
|---|---|
| `fresh --cmd config show` | 実効設定（マージ後の全設定）を表示 |
| `fresh --cmd config paths` | 設定・データ・ログのディレクトリを表示 |
| `fresh --cmd grammar list` | 利用可能な文法（シンタックス）を一覧 |
| `fresh --cmd init` | 新しいプラグイン / テーマ / 言語を初期化 |

### デーモン（セッション）

| コマンド | 説明 |
|---|---|
| `fresh -a [NAME]` | デーモンに接続（NAME 省略でカレントディレクトリ） |
| `fresh --cmd daemon list` | アクティブなデーモンを一覧 |
| `fresh --cmd daemon new <NAME>` | 名前付きデーモンを新規起動 |
| `fresh --cmd daemon kill [NAME]` | デーモンを終了 |
| `fresh --cmd daemon open-file <NAME> <FILES> [--wait]` | デーモンでファイルを開く（`.` でカレント、`--wait` は閉じるまでブロック） |

### 主なオプション

| オプション | 説明 |
|---|---|
| `--config <PATH>` | 設定ファイルのパスを指定 |
| `--safe` | init.ts・全プラグインを読み込まないセーフモード（復旧用） |
| `--no-plugins` / `--no-init` | プラグイン / `init.ts` を読み込まない |
| `--no-restore` / `--restore` | 前回ワークスペースの復元を抑止 / 強制 |
| `--locale <CODE>` | ロケールを上書き（`en` / `ja` / `zh-CN` など） |
| `-h, --help` / `-V, --version` | ヘルプ / バージョン表示 |

### リモート編集（SSH）

```bash
fresh ssh://[user@]host[:port]/path[:line[:col]]   # URL 形式
fresh user@host:path[:line[:col]]                  # scp 形式
```

> ファイル・統合ターミナル・LSP はすべてリモートホスト上で動作します。

### git のエディタとして使う

```bash
git config core.editor 'fresh --cmd daemon open-file . --wait'
```

## エディタ内ショートカット

既定キーマップ `macos`（`default` 基本 + macOS 差分、**Ctrl 中心**）の主なショートカットです。キーマップは切り替え可能で、正確な最新の割り当ては後述の方法で確認できます。

### ファイル・編集

| キー | アクション |
|---|---|
| `Ctrl+S` | 保存 |
| `Ctrl+O` | ファイルを開く |
| `Ctrl+Q` | 終了 |
| `Alt+W` | タブ/バッファを閉じる |
| `Ctrl+Z` / `Ctrl+R` | 元に戻す / やり直し |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | コピー / 切り取り / 貼り付け |
| `Ctrl+/` | コメントのトグル |
| `Ctrl+K` / `Ctrl+U` | 行末まで / 行頭まで削除 |
| `Alt+↑` / `Alt+↓` | 行を上 / 下へ移動 |
| `Alt+U` / `Alt+L` | 選択を大文字 / 小文字化 |

### 移動・ナビゲーション

| キー | アクション |
|---|---|
| `Ctrl+A` / `Ctrl+E` | 行頭 / 行末へ（※ Ctrl+A は「全選択」ではない） |
| `Ctrl+←` / `Ctrl+→` | 単語単位で移動（`Alt+←/→` も可） |
| `Ctrl+Home` / `Ctrl+End` | ファイル先頭 / 末尾へ |
| `Ctrl+L` | 指定行へジャンプ |
| `Ctrl+-` / `Ctrl+]` | 履歴を戻る / 進む |
| `Ctrl+B` | ファイルエクスプローラの開閉 |
| `Ctrl+.` / `Ctrl+,` | 定義へ移動 / 参照を検索（LSP） |

### 検索・置換

| キー | アクション |
|---|---|
| `Ctrl+F` | 検索 |
| `Ctrl+G` | 次を検索（`F3` / `Shift+F3` = 次 / 前） |
| `Alt+A` | 検索＆置換を開始 |
| `Ctrl+Alt+→` / `←` | 置換して次 / 前へ |
| `F8` / `Shift+F8` | 次 / 前のエラーへジャンプ |

### マルチカーソル・選択

| キー | アクション |
|---|---|
| `Ctrl+D` | 次の一致にカーソル追加 |
| `Ctrl+Alt+↑` / `↓` | 上 / 下にカーソル追加 |
| `Alt+Shift+I` | 選択行すべての行末にカーソル |
| `Shift+←/→/↑/↓` | 範囲選択 |
| `Alt+Shift+←/→/↑/↓` | 矩形（ブロック）選択 |

### パレット・メニュー

| キー | アクション |
|---|---|
| `Ctrl+P` | クイックオープン（ファイル / `>`コマンド / `#`バッファ / `:`行） |
| `Ctrl+T` | コマンドパレット |
| `Ctrl+'` / `Ctrl+;` | ファイル検索 / バッファ検索 |
| `F10` | メニューバーを開く（`Alt+F/E/V/G/H` で各メニュー） |

### キーマップの切り替えと確認

- 選べるキーマップ: **Default / macOS（既定）/ macOS GUI（Cmd 系）/ VSCode / Emacs**。メニューまたはコマンドパレットの「Select Keybinding Map」で切り替えます。
  - **macOS GUI** にすると `Cmd+S`保存 / `Cmd+A`全選択 / `Cmd+P`パレットなど一般的な Mac の Cmd 操作になります（ターミナルが Cmd を転送できる場合）。
- 分割・タブ切替などメニュー主体の操作も多いため、**正確な最新の割り当ては Help メニュー →「Keyboard Shortcuts」またはコマンドパレット（`Ctrl+T`）で確認**してください。編集は Edit メニュー →「Keybinding Editor」から行えます。

## 設定の反映

`config.json` はシンボリックリンクのため、編集後に Fresh を再起動すれば反映されます。設定が壊れて起動できなくなった場合は `fresh --safe` で復旧してください。
