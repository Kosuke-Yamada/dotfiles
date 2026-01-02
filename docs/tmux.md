# tmux キーバインド

Zellij 風のモードベースキーバインド設定です。

## 基本設定

- **Prefix キー**: `Ctrl+Space`
- **マウス**: 有効
- **モードキー**: vi

## モード切り替え（root テーブル）

| キー | モード | 説明 |
|------|--------|------|
| `Ctrl+p` | pane | ペイン操作モード |
| `Ctrl+t` | tab | タブ（ウィンドウ）操作モード |
| `Ctrl+n` | resize | リサイズモード |
| `Ctrl+h` | move | ペイン移動モード |
| `Ctrl+s` | scroll | スクロール/コピーモード |
| `Ctrl+o` | session | セッション操作モード |
| `Ctrl+g` | locked | ロックモード（キー入力スルー） |
| `Ctrl+q` | - | tmux 終了（確認あり） |

## pane モード

ペインの分割・移動・削除を行います。

| キー | アクション | 説明 |
|------|-----------|------|
| `c` | split-window -v | 下にペインを分割 |
| `v` | split-window -h | 右にペインを分割 |
| `h` | select-pane -L | 左のペインへ移動 |
| `j` | select-pane -D | 下のペインへ移動 |
| `k` | select-pane -U | 上のペインへ移動 |
| `l` | select-pane -R | 右のペインへ移動 |
| `n` | select-pane -t :.+ | 次のペインへ |
| `p` | select-pane -t :.- | 前のペインへ |
| `Ctrl+d` | kill-pane | ペインを閉じる |
| `Escape` / `Enter` | - | root モードに戻る |

## tab モード

ウィンドウ（タブ）の操作を行います。

| キー | アクション | 説明 |
|------|-----------|------|
| `c` | new-window | 新しいウィンドウを作成 |
| `n` | next-window | 次のウィンドウへ |
| `p` | previous-window | 前のウィンドウへ |
| `1`〜`9` | select-window -t :N | ウィンドウ N に移動 |
| `r` | rename-window | ウィンドウ名を変更 |
| `Ctrl+d` | kill-window | ウィンドウを閉じる |
| `Escape` / `Enter` | - | root モードに戻る |

## session モード

セッションの操作を行います。

| キー | アクション | 説明 |
|------|-----------|------|
| `d` | detach-client | セッションから切り離す |
| `w` | choose-tree -Zs | セッション/ウィンドウ一覧を表示 |
| `s` | new-session | 新しいセッションを作成 |
| `r` | rename-session | セッション名を変更 |
| `Escape` / `Enter` | - | root モードに戻る |

## resize モード

ペインのサイズを変更します。

| キー | アクション | 説明 |
|------|-----------|------|
| `h` | resize-pane -L 5 | 左に 5 セル拡大 |
| `j` | resize-pane -D 5 | 下に 5 セル拡大 |
| `k` | resize-pane -U 5 | 上に 5 セル拡大 |
| `l` | resize-pane -R 5 | 右に 5 セル拡大 |
| `H` | resize-pane -L 1 | 左に 1 セル拡大 |
| `J` | resize-pane -D 1 | 下に 1 セル拡大 |
| `K` | resize-pane -U 1 | 上に 1 セル拡大 |
| `L` | resize-pane -R 1 | 右に 1 セル拡大 |
| `-` | resize-pane -D 2 | 下に 2 セル拡大 |
| `=` | resize-pane -U 2 | 上に 2 セル拡大 |
| `Escape` / `Enter` | - | root モードに戻る |

## move モード

ペインの位置を入れ替えます。

| キー | アクション | 説明 |
|------|-----------|------|
| `h` | swap-pane -s '{left-of}' | 左のペインと入れ替え |
| `j` | swap-pane -s '{down-of}' | 下のペインと入れ替え |
| `k` | swap-pane -s '{up-of}' | 上のペインと入れ替え |
| `l` | swap-pane -s '{right-of}' | 右のペインと入れ替え |
| `n` / `Tab` | swap-pane -D | 次のペインと入れ替え |
| `Escape` / `Enter` | - | root モードに戻る |

## scroll モード（copy-mode）

スクロール、検索、テキスト選択・コピーを行います。

### 移動

| キー | アクション | 説明 |
|------|-----------|------|
| `j` | cursor-down | 1 行下へ |
| `k` | cursor-up | 1 行上へ |
| `d` | halfpage-down | 半ページ下へ |
| `u` | halfpage-up | 半ページ上へ |
| `f` | page-down | 1 ページ下へ |
| `b` | page-up | 1 ページ上へ |
| `G` | history-bottom | 最下部へ |
| `g` | history-top | 最上部へ |

### 検索

| キー | アクション | 説明 |
|------|-----------|------|
| `/` | search-forward | 前方検索 |
| `?` | search-backward | 後方検索 |
| `n` | search-again | 次の検索結果へ |
| `N` | search-reverse | 前の検索結果へ |

### 選択・コピー

| キー | アクション | 説明 |
|------|-----------|------|
| `v` | begin-selection | 選択開始 |
| `V` | select-line | 行選択 |
| `Ctrl+v` | rectangle-toggle | 矩形選択切り替え |
| `y` | copy-pipe-and-cancel | 選択範囲をコピー（pbcopy） |
| `Enter` | copy-pipe-and-cancel | 選択範囲をコピー（pbcopy） |

### 終了

| キー | アクション | 説明 |
|------|-----------|------|
| `q` / `Escape` | cancel | scroll モードを終了 |
| `Ctrl+s` | cancel | scroll モードを終了 |

## locked モード

キー入力を tmux がスルーするモードです。

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+l` | - | root モードに戻る（ロック解除） |

## グローバルショートカット（Alt キー）

どのモードからでも使用できます。

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+-` | resize-pane -D 2 | ペインを下に縮小 |
| `Alt+=` | resize-pane -U 2 | ペインを上に拡大 |
| `Alt+f` | resize-pane -Z | ペインをズーム切り替え |

## Prefix ショートカット

`Ctrl+Space` の後に押すキーです。

| キー | アクション | 説明 |
|------|-----------|------|
| `:` | command-prompt | コマンドプロンプトを開く |
| `r` | source-file | 設定ファイルをリロード |
| `S` | synchronize-panes | ペイン同期切り替え |
| `N` | new-session | 新しいセッション作成 |

## マウス操作

| 操作 | 説明 |
|------|------|
| クリック | ペインを選択 |
| ドラッグ | テキスト選択（copy-mode に自動移行） |
| ドラッグ終了 | 選択範囲をクリップボードにコピー |
| ホイールスクロール | copy-mode に入ってスクロール |

## ステータスバー

2 行のステータスバーが表示されます：

- **上段**: 現在のディレクトリパス
- **下段**: セッション名、タブ一覧、現在のモードに応じたヘルプ

## 修飾キーの参考

| 表記 | キー |
|------|------|
| `C-` / `Ctrl+` | Control |
| `M-` / `Alt+` | Option (Alt) |
| `S-` / `Shift+` | Shift |
