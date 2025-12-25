# skhd キーバインド

macOS 専用のホットキー設定です。

## アプリケーション起動

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+Return` | open -na "Ghostty" | Ghostty ターミナルを起動 |
| `Alt+B` | open -na "Arc" | Arc ブラウザを起動 |
| `Alt+E` | open -na "Finder" | Finder を起動 |

## 設定リロード

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+Alt+R` | skhd --reload | skhd 設定をリロード |

## スクリーンショット

| キー | アクション | 説明 |
|------|-----------|------|
| `Cmd+Shift+4` | screencapture -i | 範囲選択スクリーンショット（デスクトップに保存） |

## Yabai 連携（コメントアウト中）

以下のキーバインドは yabai（タイリングウィンドウマネージャー）用にコメントアウトされています。yabai を使用する場合は `.config/skhd/skhdrc` でコメントを解除してください。

### ウィンドウフォーカス移動

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+H` | focus west | 左のウィンドウにフォーカス |
| `Alt+J` | focus south | 下のウィンドウにフォーカス |
| `Alt+K` | focus north | 上のウィンドウにフォーカス |
| `Alt+L` | focus east | 右のウィンドウにフォーカス |

### ウィンドウ移動（スワップ）

| キー | アクション | 説明 |
|------|-----------|------|
| `Shift+Alt+H` | swap west | 左のウィンドウと入れ替え |
| `Shift+Alt+J` | swap south | 下のウィンドウと入れ替え |
| `Shift+Alt+K` | swap north | 上のウィンドウと入れ替え |
| `Shift+Alt+L` | swap east | 右のウィンドウと入れ替え |

### ウィンドウサイズ変更

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+Alt+H` | resize left | 左方向にリサイズ |
| `Ctrl+Alt+J` | resize down | 下方向にリサイズ |
| `Ctrl+Alt+K` | resize up | 上方向にリサイズ |
| `Ctrl+Alt+L` | resize right | 右方向にリサイズ |

### スペース（デスクトップ）操作

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+1〜5` | space --focus N | スペース 1〜5 に移動 |
| `Shift+Alt+1〜5` | window --space N | ウィンドウをスペース 1〜5 に移動 |

### ウィンドウレイアウト

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+F` | toggle zoom-fullscreen | フルスクリーン切り替え |
| `Alt+T` | toggle float | フローティング切り替え |
| `Ctrl+Alt+B` | layout bsp | BSP レイアウトに変更 |
| `Ctrl+Alt+S` | layout stack | スタックレイアウトに変更 |
| `Ctrl+Alt+F` | layout float | フロートレイアウトに変更 |

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

## 注意事項

### アクセシビリティ権限

skhd を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `/opt/homebrew/bin/skhd` を追加して有効化
3. 以下のコマンドでサービスを再起動:
   ```bash
   skhd --restart-service
   ```

### サービス管理

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
