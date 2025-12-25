# Zellij キーバインド

Zellij のカスタムキーバインド設定です。デフォルトのキーバインドはクリアされ、以下のカスタム設定が適用されています。

## モード切り替え（Normal モードから）

| キー | 遷移先モード | 説明 |
|------|-------------|------|
| `Ctrl+g` | Locked | 入力ロックモード |
| `Ctrl+h` | Move | ペイン移動モード |
| `Ctrl+n` | Resize | リサイズモード |
| `Ctrl+o` | Session | セッション管理モード |
| `Ctrl+p` | Pane | ペイン操作モード |
| `Ctrl+s` | Scroll | スクロールモード |
| `Ctrl+t` | Tab | タブ操作モード |
| `Ctrl+q` | - | Zellij 終了 |

## Pane モード（`Ctrl+p` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `c` | NewPane "down" | 下に新規ペイン作成 |
| `v` | NewPane "right" | 右に新規ペイン作成 |
| `n` | FocusNextPane | 次のペインにフォーカス |
| `p` | FocusPreviousPane | 前のペインにフォーカス |
| `r` | PaneNameInput | ペイン名を変更 |
| `Ctrl+d` | CloseFocus | 現在のペインを閉じる |
| `Ctrl+p` | - | Normal モードに戻る |
| `Ctrl+t` | - | Tab モードに移動 |
| `Enter` | - | Normal モードに戻る |

## Tab モード（`Ctrl+t` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `1-5` | GoToTab N | タブ 1〜5 に移動 |
| `c` | NewTab | 新規タブ作成 |
| `n` | GoToNextTab | 次のタブに移動 |
| `p` | GoToPreviousTab | 前のタブに移動 |
| `r` | TabNameInput | タブ名を変更 |
| `Ctrl+d` | CloseTab | 現在のタブを閉じる |
| `Ctrl+p` | - | Pane モードに移動 |
| `Ctrl+t` | - | Normal モードに戻る |
| `Enter` | - | Normal モードに戻る |

## Session モード（`Ctrl+o` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `d` | Detach | セッションからデタッチ |
| `w` | session-manager | セッションマネージャーを開く |
| `Ctrl+o` | - | Normal モードに戻る |
| `Ctrl+p` | - | Pane モードに移動 |
| `Ctrl+t` | - | Tab モードに移動 |
| `Enter` | - | Normal モードに戻る |

## Locked モード（`Ctrl+g` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+l` | - | Normal モードに戻る |

## Resize モード（`Ctrl+n` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `-` | Resize "Decrease" | サイズを縮小 |
| `=` | Resize "Increase" | サイズを拡大 |
| `h` | Resize "Increase left" | 左方向に拡大 |
| `j` | Resize "Increase down" | 下方向に拡大 |
| `k` | Resize "Increase up" | 上方向に拡大 |
| `l` | Resize "Increase right" | 右方向に拡大 |
| `H` | Resize "Decrease left" | 左方向に縮小 |
| `J` | Resize "Decrease down" | 下方向に縮小 |
| `K` | Resize "Decrease up" | 上方向に縮小 |
| `L` | Resize "Decrease right" | 右方向に縮小 |
| `Ctrl+n` | - | Normal モードに戻る |

## Move モード（`Ctrl+h` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `h` | MovePane "left" | ペインを左に移動 |
| `j` | MovePane "down" | ペインを下に移動 |
| `k` | MovePane "up" | ペインを上に移動 |
| `l` | MovePane "right" | ペインを右に移動 |
| `n` / `Tab` | MovePane | 次の位置に移動 |
| `Ctrl+h` | - | Normal モードに戻る |

## Scroll モード（`Ctrl+s` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `j` | ScrollDown | 1行下にスクロール |
| `k` | ScrollUp | 1行上にスクロール |
| `d` | HalfPageScrollDown | 半ページ下にスクロール |
| `u` | HalfPageScrollUp | 半ページ上にスクロール |
| `b` | PageScrollUp | 1ページ上にスクロール |
| `f` | PageScrollDown | 1ページ下にスクロール |
| `G` | ScrollToBottom | 最下部にスクロール |
| `e` | EditScrollback | スクロールバックをエディタで開く |
| `s` | SearchInput | 検索モードに入る |
| `Ctrl+s` | - | Normal モードに戻る |

## Search モード（Scroll モードから `s` で入る）

| キー | アクション | 説明 |
|------|-----------|------|
| `n` | Search "down" | 次の検索結果 |
| `N` | Search "up" | 前の検索結果 |
| `c` | Toggle CaseSensitivity | 大文字小文字の区別を切り替え |
| `w` | Toggle Wrap | ラップ検索を切り替え |
| `o` | Toggle WholeWord | 単語全体マッチを切り替え |

## 共通キーバインド

全モード共通で使用可能（一部モードを除く）:

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+-` | Resize "Decrease" | サイズを縮小 |
| `Alt+=` | Resize "Increase" | サイズを拡大 |
| `Alt+f` | ToggleFloatingPanes | フローティングペインの切り替え |
| `Esc` | - | Normal モードに戻る |

## 設定値

| 設定 | 値 | 説明 |
|------|-----|------|
| theme | catppuccin-mocha | カラーテーマ |
| default_shell | zsh | デフォルトシェル |
| default_layout | compact | デフォルトレイアウト |
| simplified_ui | true | シンプルな UI |
| pane_frames | false | ペイン枠を非表示 |
| mouse_mode | true | マウス操作を有効化 |
| copy_on_select | true | 選択時にコピー |
| copy_command | pbcopy | コピーコマンド（macOS） |
| scroll_buffer_size | 50000 | スクロールバッファサイズ |
