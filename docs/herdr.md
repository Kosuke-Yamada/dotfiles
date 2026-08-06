# herdr キーバインド

AI エージェント対応のターミナルマルチプレクサ [herdr](https://herdr.dev) のキーバインド設定です。設定ファイルは `src/.config/herdr/config.toml`。

## 基本設定

- **Prefix キー**: `Ctrl+B`
- **テーマ**: catppuccin
- herdr は**単一 prefix のみ**対応（tmux のような複数モード/複数リーダーは不可）。バインドは `prefix+<key>` 形式、または単発チョード（例 `ctrl+alt+n`）のみ。

以下の表の「キー」は Prefix（`Ctrl+B`）を押した後に続けて押すキーです。

## 全般

| キー | アクション | 説明 |
|------|-----------|------|
| `prefix+?` | help | ヘルプ |
| `prefix+i` | goto | goto |
| `prefix+Ctrl+S` | toggle_sidebar | サイドバー開閉 |
| `prefix+s` | settings | 設定（既定） |
| `prefix+q` | detach | デタッチ（既定） |
| `prefix+Shift+R` | reload_config | 設定リロード（既定） |

> `edit_scrollback`（スクロールバック編集）と `open_notification_target`（通知先を開く）は無効化しています。

## ペイン

| キー | アクション | 説明 |
|------|-----------|------|
| `prefix+←/↓/↑/→` | focus_pane_* | フォーカス移動（左/下/上/右） |
| `prefix+h` | split_horizontal | 上下分割 |
| `prefix+v` | split_vertical | 左右分割 |
| `prefix+g` | （カスタム） | 2x2 の 4 分割 |
| `prefix+z` | last_pane | 直前のペインへ |
| `prefix+Ctrl+P` | close_pane | ペインを閉じる |
| `prefix+r` | resize_mode | リサイズモード（既定） |
| `prefix+Shift+P` | rename_pane | ペイン名を変更（既定） |

> `cycle_pane_next` / `cycle_pane_previous` と `zoom`（全画面）は無効化しています。

## タブ

| キー | アクション | 説明 |
|------|-----------|------|
| `prefix+t` | new_tab | タブ作成 |
| `prefix+Ctrl+T` | close_tab | タブを閉じる |
| `prefix+p` | previous_tab | 前のタブへ（既定） |
| `prefix+n` | next_tab | 次のタブへ（既定） |
| `prefix+1`〜`9` | switch_tab | 番号でタブ切替（既定） |
| `prefix+Shift+T` | rename_tab | タブ名を変更（既定） |

## ワークスペース

| キー | アクション | 説明 |
|------|-----------|------|
| `prefix+w` | new_workspace | 新規ワークスペース |
| `prefix+f` | next_workspace | 次のワークスペース |
| `prefix+b` | previous_workspace | 前のワークスペース |
| `prefix+Ctrl+W` | close_workspace | ワークスペースを閉じる |
| `prefix+Shift+W` | rename_workspace | ワークスペース名を変更（既定） |
| `prefix+Shift+G` | new_worktree | 新規 worktree（既定） |

> `workspace_picker`（一覧）は無効化しています。

## エージェント

| キー | アクション | 説明 |
|------|-----------|------|
| `prefix+k` | previous_agent | 前のエージェントへ |
| `prefix+j` | next_agent | 次のエージェントへ |

## カスタムコマンド（2x2 分割）

herdr には 4 分割の組み込みアクションが無いため、Socket API の `herdr pane split` を組み合わせて `prefix+g` に割り当てています。

1. 起点ペイン A を下に分割 → B（A: 上 / B: 下、全幅）
2. A を右に分割 → 上段: A｜右上
3. B を右に分割 → 下段: B｜右下 ＝ 2x2

## シェルの実行状態を agents 一覧に表示

`src/.zshrc` の zsh フックで、**コマンド実行中のシェルペインだけ** agents 一覧に `shell` として表示します。プロンプトに戻ると一覧から消えます。ラベルには実行中のコマンド名（`npm`、`make` など）が出ます。

仕組みは Socket API の 3 コマンドだけです。

| タイミング | 実行内容 |
|-----------|---------|
| `preexec` | `herdr pane report-metadata … --display-agent <cmd>` → `herdr pane report-agent … --state working` |
| `precmd` / `zshexit` | `--clear-display-agent` → `herdr pane release-agent …` |

- ペインの識別には herdr が各ペインに渡す `$HERDR_PANE_ID` を使用
- `claude` などの対話エージェントは herdr の組み込み統合（`herdr integration install claude`）が自前で状態報告するため、権限が競合しないよう除外リストで報告をスキップ
- CLI 呼び出しは 1 回あたり約 9ms。1 コマンドにつき往復 2 回で、プロンプト体感への影響はほぼ無し

## 設定の反映

config.toml を編集したら、稼働中のサーバーに再読み込みさせます。

```bash
herdr server reload-config
```
