# yabai 設定

macOS 専用のタイリングウィンドウマネージャーです。

## 概要

yabai は macOS 用の軽量なタイリングウィンドウマネージャーです。skhd と組み合わせることで、キーボードショートカットでウィンドウを操作できます。

## 現在の設定

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

## ウィンドウ配置（skhd 連携）

skhd と連携して、以下のキーバインドでウィンドウを配置できます。

| キー | 説明 |
|------|------|
| `Alt+Cmd+→` | 右半分に配置 |
| `Alt+Cmd+←` | 左半分に配置 |
| `Alt+Cmd+↑` | 上半分に配置 |
| `Alt+Cmd+↓` | 下半分に配置 |

## grid コマンドの解説

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

## サービス管理

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

yabai を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `/opt/homebrew/bin/yabai` を追加して有効化
3. 以下のコマンドでサービスを再起動:
   ```bash
   yabai --restart-service
   ```

### SIP について

yabai のフル機能（ウィンドウの自動タイリング、スペース管理など）を使用するには、System Integrity Protection (SIP) の一部を無効にする必要があります。ただし、本設定ではフロートモード + 手動配置を使用しているため、SIP の変更は不要です。

## 参考リンク

- [yabai GitHub](https://github.com/koekeishiya/yabai)
- [yabai Wiki](https://github.com/koekeishiya/yabai/wiki)
