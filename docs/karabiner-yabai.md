# Karabiner & yabai キーバインド

macOS 専用のキー割り当て（Karabiner-Elements）とタイリングウィンドウマネージャー（yabai）の設定です。

## 概要

- **Karabiner-Elements**: キーの変換（Caps Lock → Hyper）と、ショートカットからのコマンド実行（`shell_command`）
- **yabai**: macOS 用のタイリングウィンドウマネージャー

設定は `src/.config/karabiner/karabiner.json` で管理し、`make link`（`make karabiner-config`）で
`~/.config/karabiner/karabiner.json` に配置します。Karabiner はファイル単体のシンボリックリンクでは変更を検知しないため、通常ファイルとしてコピーします。

以前は skhd を使っていましたが、いずれかのプロセスがセキュア入力（Secure Keyboard Entry）を有効にしたままだと
skhd は起動できず、全ショートカットが効かなくなるため廃止しました。Karabiner はセキュア入力の影響を受けません。
`make link` を実行すると、旧環境の skhd のサービスと設定ファイルのリンクも片付けます。

`Hyper` は Caps Lock（Karabiner で `Ctrl+Option+Shift+Cmd` に変換）です。

## アプリケーション起動・切り替え

| キー | アクション | 説明 |
|------|-----------|------|
| `Alt+Return` | open -na Ghostty | Ghostty ターミナルを起動 |
| `Alt+B` | open -na Arc | Arc ブラウザを起動 |
| `Alt+E` | open -na Finder | Finder を起動 |
| `Hyper+F` | t3-toggle | T3 Code |
| `Hyper+B` | app-toggle com.google.Chrome | Google Chrome |
| `Hyper+D` | app-toggle com.openai.codex | ChatGPT（Codex アプリ） |
| `Hyper+G` | app-toggle com.google.GeminiMacOS | Gemini |
| `Hyper+C` | app-toggle com.anthropic.claudefordesktop | Claude |
| `Hyper+S` | app-toggle com.tinyspeck.slackmacgap | Slack |
| `Hyper+N` | app-toggle notion.id | Notion |
| `Hyper+M` | app-toggle com.meta.endo | Meta のアプリ（bundle ID: com.meta.endo） |
| `Hyper+K` | app-toggle com.amazon.Lassen | Kindle |
| `Hyper+V` | app-toggle com.microsoft.VSCode | VS Code |

`app-toggle` / `t3-toggle` は `make link` で `~/.local/bin` に配置します。対象アプリが最前面なら非表示にし、
それ以外なら現在のデスクトップに移動して前面に表示します（未起動なら起動）。

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
| `Alt+Cmd+_` | grid 1:1:0:0:1:1 | ウィンドウを全画面に配置（JIS キーボードの `_` キー） |

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

## その他

| キー | アクション | 説明 |
|------|-----------|------|
| `Ctrl+G` | Ghostty のメニュー項目をクリック | Quick Terminal の表示/非表示 |
| `Ctrl+Alt+Y` | yabai --restart-service | yabai を再起動して復旧 |

Ghostty のグローバルキーバインドはスリープ復帰後に無効化されることがあるため、`Ctrl+G` は
System Events 経由でメニュー項目「Quick Terminal」をクリックします。初回は Karabiner-Elements に
アクセシビリティ（オートメーション）の許可を求められることがあります。

Karabiner の設定は `~/.config/karabiner/karabiner.json` を保存すると自動で再読み込みされます。

### リサイズ等が「効かない・重い」ときの対処

yabai サーバはスリープ復帰や特定アプリの Accessibility 応答待ちなどをきっかけに
ハング状態になり、`resize` / `move` / `focus` などの**操作コマンドが数十秒〜数分
ブロック**されることがあります（`yabai -m query ...` は正常に即返るのが見分け方）。

通常のショートカットは `~/.local/bin/yabai-run` 経由で実行します。
操作が2秒以内に完了しない場合、またはサービスに接続できない場合は、
自動で再起動して元の操作を1回だけ再試行します。

再起動後の起動待ちは通常操作と分けて最大30秒待ちます。
復旧中に押したキーは蓄積せず終了し、同時にタイムアウトした操作による
再起動の繰り返しを防ぎます。ロックはプロセス終了時に自動で解除されます。
再起動に失敗した場合は、そのエラーを表示して終了します。

手動で復旧する場合は **`Ctrl+Alt+Y`**（または `yabai --restart-service`）を使用します。
起動に15秒以上かかる場合があるため、連続して再起動せず完了を待ってください。
生の `yabai -m ...` コマンドにはこの保護はありません。ターミナルでも必要に応じて
`yabai-run window --grid 1:2:0:0:1:1` のように実行できます。

待ち時間は `YABAI_RUN_TIMEOUT`（通常操作、既定2秒）、
`YABAI_RUN_READY_TIMEOUT`（起動待ち、既定30秒）、
`YABAI_RUN_RESTART_TIMEOUT`（再起動コマンド、既定10秒）で調整できます。

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

| 表記 | キー | Karabiner の modifier |
|------|------|------|
| `Cmd` | Command | `command` |
| `Alt` | Option | `option` |
| `Ctrl` | Control | `control` |
| `Shift` | Shift | `shift` |
| `Hyper` | Caps Lock（Cmd + Alt + Ctrl + Shift） | 4 つすべて |

## サービス管理

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

yabai を使用するには、アクセシビリティ権限が必要です:

1. **システム設定** > **プライバシーとセキュリティ** > **アクセシビリティ** を開く
2. `$(brew --prefix)/bin/yabai` の実際のパスを追加して有効化（Apple Silicon は `/opt/homebrew/bin`、Intel Mac は `/usr/local/bin`）
3. 以下のコマンドでサービスを再起動:
   ```bash
   yabai --restart-service
   ```

Karabiner-Elements には、システム設定 > 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 の
`.Karabiner-VirtualHIDDevice-Manager` と、プライバシーとセキュリティ > 入力監視 の
`karabiner_grabber` / `Karabiner-Core-Service` の許可が必要です。

### SIP について

yabai のフル機能（ウィンドウの自動タイリング、スペース管理など）を使用するには、System Integrity Protection (SIP) の一部を無効にする必要があります。ただし、本設定ではフロートモード + 手動配置を使用しているため、SIP の変更は不要です。

## 参考リンク

- [Karabiner-Elements](https://karabiner-elements.pqrs.org/)
- [yabai GitHub](https://github.com/koekeishiya/yabai)
- [yabai Wiki](https://github.com/koekeishiya/yabai/wiki)
