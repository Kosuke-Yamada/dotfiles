# skhd & yabai キーバインド

macOS 専用のホットキー（skhd）とタイリングウィンドウマネージャー（yabai）の設定です。

## 概要

- **skhd**: macOS 用のホットキーデーモン
- **yabai**: macOS 用のタイリングウィンドウマネージャー

両者を組み合わせることで、キーボードショートカットでウィンドウを操作できます。

## アプリケーション起動

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+Return` | open -na "Ghostty" | Ghostty ターミナルを起動 |
| `Alt+B` | open -na "Arc" | Arc ブラウザを起動 |
| `Alt+E` | open -na "Finder" | Finder を起動 |

## ウィンドウフォーカス移動

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+H` | focus west | 左のウィンドウにフォーカス |
| `Alt+J` | focus south | 下のウィンドウにフォーカス |
| `Alt+K` | focus north | 上のウィンドウにフォーカス |
| `Alt+L` | focus east | 右のウィンドウにフォーカス |

## ウィンドウ移動（スワップ）

| キー | アクション | 説明 |
|------|-----------|------|
| `Shift+Alt+H` | swap west | 左のウィンドウと入れ替え |
| `Shift+Alt+J` | swap south | 下のウィンドウと入れ替え |
| `Shift+Alt+K` | swap north | 上のウィンドウと入れ替え |
| `Shift+Alt+L` | swap east | 右のウィンドウと入れ替え |

## ウィンドウサイズ変更

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+Alt+H` | 幅を縮める | 中央基準で幅を 100px 縮小 |
| `Ctrl+Alt+L` | 幅を広げる | 中央基準で幅を 100px 拡大 |
| `Ctrl+Alt+K` | 高さを広げる | 中央基準で高さを 100px 拡大 |
| `Ctrl+Alt+J` | 高さを縮める | 中央基準で高さを 100px 縮小 |

> 各方向で両辺を同時に動かすため、片側が画面端に達していても反対側が動き、float レイアウトでも止まりにくくなっています。

## ウィンドウ配置（グリッド）

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+Cmd+→` | grid 1:2:1:0:1:1 | ウィンドウを右半分に配置 |
| `Alt+Cmd+←` | grid 1:2:0:0:1:1 | ウィンドウを左半分に配置 |
| `Alt+Cmd+↑` | grid 2:1:0:0:1:1 | ウィンドウを上半分に配置 |
| `Alt+Cmd+↓` | grid 2:1:0:1:1:1 | ウィンドウを下半分に配置 |
| `Shift+Alt+Cmd+_` | grid 1:1:0:0:1:1 | ウィンドウを全画面に配置 |

## スペース（デスクトップ）操作

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+1`〜`5` | space --focus N | スペース 1〜5 に移動 |
| `Shift+Alt+1`〜`5` | window --space N | ウィンドウをスペース 1〜5 に移動 |

## ウィンドウレイアウト

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+F` | toggle zoom-fullscreen | フルスクリーン切り替え |
| `Alt+T` | toggle float | フローティング切り替え |
| `Ctrl+Alt+B` | layout bsp | BSP レイアウトに変更 |
| `Ctrl+Alt+S` | layout stack | スタックレイアウトに変更 |
| `Ctrl+Alt+F` | layout float | フロートレイアウトに変更 |

## 設定リロード / 復旧

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+Alt+R` | skhd --reload | skhd 設定をリロード |
| `Ctrl+Alt+Y` | yabai --restart-service | yabai を再起動して復旧 |

### リサイズ等が「効かない・重い」ときの対処

yabai サーバはスリープ復帰や特定アプリの Accessibility 応答待ちなどをきっかけに
ハング状態になり、`resize` / `move` / `focus` などの**操作コマンドが数十秒〜数分
ブロック**されることがあります（`yabai -m query ...` は正常に即返るのが見分け方）。

この状態になったら **`Ctrl+Alt+Y`**（または `yabai --restart-service`）で yabai を
再起動すると即座に復旧します。再起動後はリサイズが数十ミリ秒で完了します。

## スクリーンショット

| キー | アクション | 説明 |
|------|-----------|------|
| `Cmd+Shift+4` | screencapture -i | 範囲選択スクリーンショット（デスクトップに保存） |

## yabai 設定

### レイアウト

デフォルトでは `float`（フロート）モードを使用しています。

| 設定 | 値 | 説明 |
|------|-----|------|
| layout | float | フロートモード（手動でウィンドウ配置） |
| window_gap | 10px | ウィンドウ間の余白 |
| padding | 10px | 画面端の余白 |

### ウィンドウルール

以下のアプリケーションは自動的にフロートモードで開きます:

- System Settings / システム設定
- Calculator / 計算機
- Karabiner
- Archive Utility
- Alfred Preferences
- Activity Monitor / アクティビティモニタ
- Preview / プレビュー
- Finder
- 1Password

### grid コマンドの解説

`yabai -m window --grid <rows>:<cols>:<start-x>:<start-y>:<width>:<height>`

| パラメータ | 説明 |
|-----------|------|
| rows | グリッドの行数 |
| cols | グリッドの列数 |
| start-x | 開始位置（列、0始まり） |
| start-y | 開始位置（行、0始まり） |
| width | ウィンドウの幅（グリッド単位） |
| height | ウィンドウの高さ（グリッド単位） |

例:
- `1:2:0:0:1:1` - 左半分（1行2列のグリッドで、左側1列分）
- `1:2:1:0:1:1` - 右半分（1行2列のグリッドで、右側1列分）
- `2:2:0:0:1:1` - 左上1/4
- `2:2:1:1:1:1` - 右下1/4

## 修飾キーの参考

| 表記 | キー |
|------|------|
| `cmd` | Command |
| `alt` | Option |
| `ctrl` | Control |
| `shift` | Shift |
| `fn` | Function |
| `hyper` | Cmd + Alt + Ctrl + Shift |
| `meh` | Alt + Ctrl + Shift |

## サービス管理

### skhd

```bash
# サービス開始
skhd --start-service

# サービス停止
skhd --stop-service

# サービス再起動
skhd --restart-service

# 設定リロード
skhd --reload
```

### yabai

```bash
# サービス開始
yabai --start-service

# サービス停止
yabai --stop-service

# サービス再起動
yabai --restart-service
```

## 注意事項

### アクセシビリティ権限

skhd と yabai を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `/opt/homebrew/bin/skhd` と `/opt/homebrew/bin/yabai` を追加して有効化
3. 以下のコマンドでサービスを再起動:
   ```bash
   skhd --restart-service
   yabai --restart-service
   ```

### SIP について

yabai のフル機能（ウィンドウの自動タイリング、スペース管理など）を使用するには、System Integrity Protection (SIP) の一部を無効にする必要があります。ただし、本設定ではフロートモード + 手動配置を使用しているため、SIP の変更は不要です。

## 参考リンク

- [skhd GitHub](https://github.com/koekeishiya/skhd)
- [yabai GitHub](https://github.com/koekeishiya/yabai)
- [yabai Wiki](https://github.com/koekeishiya/yabai/wiki)
