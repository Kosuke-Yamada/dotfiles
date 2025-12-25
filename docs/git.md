# Git コマンド

`.aliases` で定義されている Git 関連のエイリアスです。

## TUI クライアント

| エイリアス | 展開後 | 説明 |
|------------|--------|------|
| `gui` | `gitui` | Git TUI クライアントを起動 |

## 基本操作

| エイリアス | 展開後 | 説明 |
|------------|--------|------|
| `ga` | `git add` | ファイルをステージ |
| `gaa` | `git add -A` | 全ての変更をステージ |
| `gc` | `git commit` | コミット |
| `gcm` | `git commit -m` | メッセージ付きコミット |
| `gf` | `git fetch` | リモートから取得 |
| `gm` | `git merge` | マージ |
| `gps` | `git push` | リモートにプッシュ |
| `gpl` | `git pull` | リモートからプル |

## ブランチ操作

| エイリアス | 展開後 | 説明 |
|------------|--------|------|
| `gb` | `git branch` | ブランチ一覧 |
| `gsw` | `git switch` | ブランチ切り替え |
| `gswc` | `git switch -c` | 新規ブランチ作成して切り替え |

## 差分・ログ

| エイリアス | 展開後 | 説明 |
|------------|--------|------|
| `gd` | `git diff` | 差分表示 |
| `gl` | `git log` | ログ表示 |
| `glo` | `git log --oneline` | ログを1行で表示 |

## 状態確認・復元

| エイリアス | 展開後 | 説明 |
|------------|--------|------|
| `gst` | `git status -u` | untracked ファイル含むステータス |
| `grs` | `git restore` | ファイルを復元 |

## 一括更新

| エイリアス | 説明 |
|------------|------|
| `gua` | dev と main ブランチを一括更新して元のブランチに戻る |

**`gua` の詳細:**
```bash
git fetch origin && \
git checkout dev && git pull origin dev && \
git checkout main && git pull origin main && \
git checkout -
```

## Git 設定（.gitconfig）

### Delta（差分表示強化）

git-delta を使用した見やすい差分表示が設定されています。

| 設定 | 値 | 説明 |
|------|-----|------|
| `core.pager` | delta | ページャーに delta を使用 |
| `interactive.diffFilter` | delta --color-only | インタラクティブモード用 |
| `delta.navigate` | true | n/N で差分間を移動可能 |
| `delta.dark` | true | ダークテーマ |
| `delta.line-numbers` | true | 行番号を表示 |

### Git LFS

Large File Storage が設定されています。

### マージ

| 設定 | 値 | 説明 |
|------|-----|------|
| `merge.conflictstyle` | zdiff | zdiff スタイルのコンフリクト表示 |
