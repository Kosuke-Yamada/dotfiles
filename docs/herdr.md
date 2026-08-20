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

## エージェントのバックグラウンドシェルを agents 一覧に表示

Claude Code が `run_in_background` で切り離したシェルが動いている間だけ、サイドバーの
agents 一覧で稼働アイコンのすぐ右に青い `●` が出ます。全部終わると `○`（空白丸）に戻ります。
「エージェントは待機に戻ったのに、まだ裏でシェルが回っている」ペインが一目で分かります。

```
●  ● dotfiles  1    ← 裏でシェルが走行中
   claude
●  ○ dotfiles  1    ← 裏で走っているシェルは無い
   claude
```

フォアグラウンドのシェル実行は対象にしません。エージェントが応答している間は左隣の
`state_icon` が既に稼働中を示すため、そこへ重ねても情報が増えないからです。

Claude Code の hooks から Socket API の `report-metadata` を呼ぶだけの仕組みです。
フックの種類で処理を分ける必要はなく、どのフックからでも「追跡中のバックグラウンドシェルの
生存状況」へ表示を合わせ直します（スクリプトは引数を取りません）。

| フック | 実行内容 |
|-------|---------|
| `PostToolUse`（matcher `Bash`） | バックグラウンド起動を捕まえて追跡に入れ、`●` / `○` を報告 |
| `Stop` / `SessionEnd` | 表示を合わせ直す（中断時の取り残し防止） |
| `SessionStart` | 表示を合わせ直す（初期表示） |

`PreToolUse` は使いません。フォアグラウンドの実行を表示しないのであれば前倒しで点灯させる
必要が無く、バックグラウンド実行では起動直後に `PostToolUse` が届くため遅れも出ないためです。
権限確認で拒否された場合に `●` が点いたまま残る問題も、同時に無くなります。

### バックグラウンドのシェルだけを見分ける

Claude Code は Bash ツール呼び出しごとに `zsh -c source ~/.claude/shell-snapshots/snapshot-*.sh …`
を claude 本体の直下に生やします。プロセスの見た目はフォアグラウンドでもバックグラウンドでも
同じで、親・プロセスグループ・`stat`・tty では区別できません。

区別できるのは **標準出力の宛先** です。`run_in_background` の出力はハーネスが
`<セッション>/tasks/<taskId>.output` へ繋ぐので、`fd 1` を見ればタスクとシェルが 1 対 1 で
対応づきます。タスク ID は `PostToolUse` のフック入力 JSON の
`tool_response.backgroundTaskId` に入っています（フォアグラウンドの実行では現れません）。

```sh
# claude 直下のシェルのうち、fd 1 が該当タスクの出力を指しているものが実行主体
lsof -p "$pid_list" -a -d 1 -Fpn | awk -v id="$task_id" '
  /^p/ { pid = substr($0, 2); next }
  /^n/ { if (substr($0, 2) ~ ("/tasks/" id "\\.output$")) print pid }
'
```

`PostToolUse` はコマンド起動の直後に届くため、シェルがまだ生えていないことがあります。
ここで取りこぼすと点灯しないままになるので、見つからなければ 1 秒だけ待ち直します。

捕まえた PID は `$TMPDIR/herdr-shell-token-<ペイン>.bg/<PID>`（中身はタスク ID）へ記録し、
以降は `ps` での生存確認だけで済ませます。`lsof` はバックグラウンド起動の瞬間しか呼びません。
タスクごとに紐づけるので、並列実行やサブエージェント経由でも、フォアグラウンドの実行が
混ざることはありません。

### 消灯のさせ方

バックグラウンド実行は起動直後に `PostToolUse` が届くため、終了はフックでは分かりません。
そこで追跡対象が残っているときは **見張りプロセス** を 1 つ切り離して起動し、3 秒ごとに
生存を確認して全部消えた時点で `○` を報告させます。実測ではタスク終了から 1〜3 秒で戻ります。

```
04秒 shell=● tracked=1   ← バックグラウンドタスク走行中
…
20秒 shell=● tracked=1
22秒 shell=○ tracked=0   ← 見張りが消滅を検知して ○ を報告
```

### 実装メモ

- スクリプトは `src/.claude/scripts/herdr-shell-token.sh`、登録は `src/.claude/settings.json` の `hooks`
- 表示位置は `config.toml` の `[ui.sidebar.agents]` の `rows`。1 行目を
  `state_icon` → `$shell` → `workspace` → `tab` の順とし、稼働アイコンの直後へ
  カスタムトークン `$shell` を差し込んでいる
- 色は `fg = "#89b4fa"`（catppuccin の `blue`）。`●` と `○` は同一トークンなので色は共通で、
  状態は記号の違いで表す（トークン単位のスタイルは静的にしか指定できない）
- `report-metadata` は display-only のメタデータ報告なので、herdr 組み込みの claude 統合
  （`herdr integration install claude`）が持つエージェント状態の報告権限とは競合しない。
  混ざらないよう `--source claude-shell` と分けている
- claude 本体の PID はフックに渡る `CLAUDE_PID` を使う。無い場合は
  `CLAUDE_CODE_MESSAGING_SOCKET`（`<pid>.sock`）から拾い、それも無ければ `$PPID` から祖先を辿る。
  祖先の照合は `comm` ではなく `command` で行う（バージョン切り替え時の実行ファイル名が
  `2.1.234` のような数字になり、`comm` では claude と判別できないため）
- 生存確認に `pgrep` は使えない。`pgrep` は自分のプロセスグループを除外するため、
  実行中の自分のシェルが見えず 0 本と誤判定する。`ps` を使う
- 追跡記録はペインごとに分ける。claude を再起動しても、消えた PID は次の生存確認で
  記録から外れるので後始末は要らない
- 見張りはペインごとに 1 つだけ。ロックは `mkdir` のアトミック性で取り、
  `trap '' HUP INT TERM` でフックの終了に道連れにされないようにし、最大 2 時間で諦める。
  異常終了でロックだけ残った場合に備え、150 分より古いロックは奪う
- ペインの識別には herdr が各ペインに渡す `$HERDR_PANE_ID` を使用。
  herdr 外（`HERDR_PANE_ID` なし）では何もせず終了する
- フックはツールの実行をブロックするため、スクリプトは失敗しても必ず `exit 0` で返す
- フック入力の JSON は読み捨てると書き込み側がブロックし得るので必ず消費する
- タスク ID は `awk` の正規表現へ埋めるため、英数字・`_`・`-` 以外が混じったら使わない
- `lsof` は macOS では PATH に無いことがあるので `/usr/sbin/lsof` をフォールバックに持つ。
  どちらも無い環境では、起動時に動いているシェルをまとめて追跡対象にする（フォアグラウンドが
  混ざり得るが、終われば次の生存確認で外れる）
- `jq` が無い環境では `sed` で `backgroundTaskId` を拾う
- コストは `herdr` CLI が 1 回約 9ms、`ps` の全プロセス列挙が約 20〜40ms、
  `lsof`（バックグラウンド起動時のみ）が約 30〜50ms
- 当初はフォアグラウンドのシェル実行も `●` にしていたが、それは `state_icon` と重複する
  情報だったため、裏で回っているシェルだけに絞った
- さらに以前は `src/.zshrc` の `preexec`/`precmd` フックで「素の zsh ペイン」を `shell`
  エージェントとして一覧に出していたが、見たいのは agents に並ぶエージェント側の状態なので置き換えた

## サイドバーの文字を読みやすくする

herdr は既定でサイドバーの 2 行目以降や補助トークンを dim 属性で描きます。
端末によっては dim が「前景色を背景と強くブレンドする」実装のため、非常に薄くなります。
`rows` のトークンをインラインテーブルで書くとトークン単位でスタイルを指定できるので、
`dim = false` で dim を解除し、補助情報には明るいグレーを明示しています。

```toml
[ui.sidebar.agents]
rows = [
  [
    "state_icon",
    { token = "$shell", dim = false, fg = "#89b4fa" },  # 実行状態の ●/○ は青
    { token = "workspace", dim = false },
    { token = "tab", dim = false, fg = "#a6adc8" },
  ],
  [{ token = "agent", dim = false, fg = "#a6adc8" }],
]
```

- 指定できるのは `token` / `fg`（`#RGB` か `#RRGGBB`）/ `bold` / `dim`。
  省略した項目は herdr の既定スタイルが保たれる
- `state_icon` と `git_status` は状態を色で示すため `fg` は指定せず、`dim` だけ解除する
- `#a6adc8` は catppuccin の `subtext0`、`#89b4fa` は `blue`。
  テーマを変える場合はこれらの値も合わせる
- サイドバー以外（ヘッダーやキーヒント、枠線）も薄い場合は、
  `[theme.custom]` で `overlay0` / `overlay1` / `subtext0` を明るい値に差し替える
- 変更後は `herdr config check` で検証してから `herdr server reload-config` で反映する。
  トークンのスタイル指定に誤りがあると `config parse error` として報告され、
  既定値へフォールバックする

## Claude Code のステータスラインに現在の作業内容を表示

Claude Code はタスク要約を端末タイトルへ書き込みますが、herdr のペインでは
ターミナルのタイトルバーが見えません。そこで `src/.claude/scripts/statusline.sh` が
Socket API 経由で自分のペインのタイトルを読み、ステータスラインへ再掲します。

ステータスラインは 2 行構成です（Claude Code は statusLine コマンドの出力を
改行で分割し、各行を順に描画します）。

```
Opus 5 ∣ Session 25% (2h 31m) ∣ Week 63% (16h 21m)
▸ herdr のステータスラインに作業内容を表示 ∣ dotfiles ∣ main*
```

| 行 | 内容 |
| --- | --- |
| 1 行目 | モデル名と使用率（Session / Week / Fable / Credits と各リセットまでの残り時間） |
| 2 行目 | 現在の作業内容の要約 / 作業ディレクトリ（リポジトリ名 + ルートからの相対パス）と git ブランチ |

- 作業内容の取得元は `herdr pane get $HERDR_PANE_ID` の `terminal_title_stripped`
- 先頭のスピナー記号（`◐` `✳` など）を除去する
- 使用率と行を分けたため既定では切り詰めない（端末幅を超えた分は Claude Code 側が切る）。
  `STATUSLINE_TASK_MAX_LEN` に正の値を設定するとその文字数で切り詰める
- `$HERDR_PANE_ID` が無い環境（herdr 外）では作業内容を省略し、2 行目はディレクトリのみになる
- ブランチ名は statusline の入力 JSON に含まれないため `git` に問い合わせる。
  未コミットの変更があるとブランチ名の末尾に `*` が付く（detached HEAD では短縮ハッシュ）

## 設定の反映

config.toml を編集したら、稼働中のサーバーに再読み込みさせます。

```bash
herdr server reload-config
```
