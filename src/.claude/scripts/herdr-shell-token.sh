#!/bin/sh
# ==============================================================================
# herdr: Claude Code のバックグラウンドシェルが動いているかを agents 一覧に表示する
# ==============================================================================
# Claude Code のフックから呼ばれ、Bash ツールの `run_in_background` で切り離した
# シェルが動いている間だけ herdr へ ● を報告し、全部終わったら ○ に戻す。
# herdr サイドバーの agents 一覧は config.toml の [ui.sidebar.agents] が
# 稼働アイコンの直後にこの値を描画する。
#
# フォアグラウンドのシェル実行は対象にしない。エージェントが応答している間は
# herdr の state_icon が既に稼働中を示すので、そこへ重ねても情報が増えない。
# 知りたいのは「エージェントは待機に戻ったのに、まだ裏で回っているシェルがあるか」。
#
# 呼び出しは引数なし。フックの種類で処理を分ける必要はなく、どのフックからでも
# 「追跡中のバックグラウンドシェルの生存状況」へ表示を合わせ直すだけ。
#   PostToolUse（matcher Bash） … run_in_background の起動を捕まえて追跡に入れる
#   Stop / SessionEnd / SessionStart … 表示を合わせ直す（取り残し・初期表示の防止）
#
# 判定はフックの回数ではなく実際のプロセスで行う。Claude Code は Bash ツール
# 呼び出しごとに `zsh -c source ~/.claude/shell-snapshots/snapshot-*.sh …` を
# claude 本体の直下へ生やし、バックグラウンド実行ではその標準出力を
# `<セッション>/tasks/<taskId>.output` へ繋ぐ。fd 1 の宛先を見ればタスクと
# シェルを 1 対 1 で対応づけられるため、並列実行やサブエージェント経由でも
# フォアグラウンドの実行と混ざらない。
#
# バックグラウンド実行はコマンド起動直後に PostToolUse が届くので、フックだけでは
# 終了を知れない。追跡対象が残っている間は見張りを 1 つ切り離して起動し、
# 全部消えた時点で ○ を報告させる。
#
# フックはツールの実行をブロックするため、失敗しても必ず終了コード 0 で返す。
# set -e は使わない（途中の失敗で非ゼロ終了させないため）。
# ------------------------------------------------------------------------------

# フック入力の JSON。読み捨てると書き込み側がブロックし得るので必ず消費する
payload=$(cat 2>/dev/null)

# herdr のペイン内でのみ動作する（HERDR_PANE_ID は herdr が各ペインへ渡す）
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

herdr_bin="${HERDR_BIN_PATH:-herdr}"
command -v "$herdr_bin" >/dev/null 2>&1 || exit 0

# 追跡記録の置き場。ペインごとに分ける（1 ファイル 1 PID、中身はタスク ID）
pane_key=$(printf '%s' "$HERDR_PANE_ID" | tr -c 'A-Za-z0-9_-' '_')
track_dir="${TMPDIR:-/tmp}/herdr-shell-token-$pane_key.bg"

# lsof は macOS では PATH に無いことがある（/usr/sbin にある）
lsof_bin=""
if command -v lsof >/dev/null 2>&1; then
  lsof_bin="lsof"
elif [ -x /usr/sbin/lsof ]; then
  lsof_bin="/usr/sbin/lsof"
fi

# バックグラウンド起動なら tool_response にタスク ID が入る（フォアグラウンドは空）
if command -v jq >/dev/null 2>&1; then
  task_id=$(printf '%s' "$payload" | jq -r '.tool_response.backgroundTaskId // empty' 2>/dev/null)
else
  task_id=$(printf '%s' "$payload" | sed -n 's/.*"backgroundTaskId":"\([^"]*\)".*/\1/p' | head -1)
fi
# 後段で awk の正規表現に埋めるため、想定外の文字が混じったら使わない
case "$task_id" in
  "") ;;
  *[!A-Za-z0-9_-]*) task_id="" ;;
esac

# claude 本体の PID。フックには CLAUDE_PID が渡る
claude_pid="${CLAUDE_PID:-}"

# 予備 1: メッセージングソケットの名前が <pid>.sock になっている
if [ -z "$claude_pid" ] && [ -n "${CLAUDE_CODE_MESSAGING_SOCKET:-}" ]; then
  claude_pid=$(basename "$CLAUDE_CODE_MESSAGING_SOCKET" .sock 2>/dev/null)
  case "$claude_pid" in
    "" | *[!0-9]*) claude_pid="" ;;
  esac
fi

# 予備 2: 祖先を辿る。comm ではなく command で照合する
# （バージョン切り替え時の実行ファイル名は "2.1.234" のような数字になるため）
if [ -z "$claude_pid" ]; then
  ancestor="$PPID"
  while [ -n "$ancestor" ] && [ "$ancestor" -gt 1 ] 2>/dev/null; do
    case "$(ps -o command= -p "$ancestor" 2>/dev/null)" in
      *claude*) claude_pid="$ancestor"; break ;;
    esac
    ancestor=$(ps -o ppid= -p "$ancestor" 2>/dev/null | tr -d ' ')
  done
fi

# display-only メタデータなので、herdr 組み込みの claude 統合が持つ
# エージェント状態の報告権限とは競合しない。source は統合と分けておく
report() {
  "$herdr_bin" pane report-metadata "$HERDR_PANE_ID" \
    --source claude-shell --token "shell=$1" >/dev/null 2>&1 || true
}

# claude 直下で動いているシェルの PID 一覧。
# pgrep は自分のプロセスグループを除外してしまうため ps を使う
live_shell_pids() {
  [ -n "$claude_pid" ] || return 0
  ps -ax -o pid=,ppid=,command= 2>/dev/null | awk -v cp="$claude_pid" '
    $2 == cp && /shell-snapshots\/snapshot-/ { print $1 }
  '
}

# 指定タスクを実行しているシェルの PID。
# fd 1 が tasks/<taskId>.output を指しているシェルが、そのタスクの実行主体。
find_task_shell_pids() {
  pid_list=$(live_shell_pids | tr '\n' ',' | sed 's/,$//')
  [ -n "$pid_list" ] || return 0
  if [ -z "$lsof_bin" ]; then
    # lsof が使えない環境では、いま動いているシェルをまとめて追跡対象にする。
    # フォアグラウンドの実行が混ざり得るが、終われば次の生存確認で外れる
    live_shell_pids
    return 0
  fi
  "$lsof_bin" -p "$pid_list" -a -d 1 -Fpn 2>/dev/null | awk -v id="$1" '
    /^p/ { pid = substr($0, 2); next }
    /^n/ { if (substr($0, 2) ~ ("/tasks/" id "\\.output$")) print pid }
  '
}

# バックグラウンド起動したシェルを PID で捕まえて追跡に入れる
track_background_shell() {
  pids=$(find_task_shell_pids "$1")
  # PostToolUse はコマンド起動の直後に届くため、シェルがまだ生えていないことがある。
  # ここで取りこぼすと点灯しないままになるので、一度だけ待ち直す
  if [ -z "$pids" ]; then
    sleep 1
    pids=$(find_task_shell_pids "$1")
  fi
  [ -n "$pids" ] || return 0
  mkdir -p "$track_dir" 2>/dev/null || return 0
  for pid in $pids; do
    printf '%s\n' "$1" > "$track_dir/$pid" 2>/dev/null
  done
}

# 追跡中のシェルのうち、まだ生きている本数。消えたものは記録から外す
background_count() {
  [ -d "$track_dir" ] || { echo 0; return; }
  live=" $(live_shell_pids | tr '\n' ' ') "
  count=0
  for entry in "$track_dir"/*; do
    [ -f "$entry" ] || continue
    pid=${entry##*/}
    case "$live" in
      *" $pid "*) count=$((count + 1)) ;;
      *) rm -f "$entry" 2>/dev/null ;;
    esac
  done
  echo "$count"
}

# 追跡対象が消えるまで待って ○ に戻す見張り。ペインに 1 つだけ立てる
# （ロックはディレクトリ作成のアトミック性で取る）
start_watcher() {
  lock="$track_dir.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    # 見張りが居る。ただし異常終了でロックだけ残ることがあるので、
    # 見張りの寿命（2 時間）を超えて古いものは奪う
    if [ -n "$(find "$lock" -maxdepth 0 -mmin +150 2>/dev/null)" ]; then
      rmdir "$lock" 2>/dev/null
      mkdir "$lock" 2>/dev/null || return 0
    else
      return 0
    fi
  fi
  (
    # フックの終了で道連れにされないようシグナルを無視する
    trap '' HUP INT TERM
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    tries=0
    while [ "$tries" -lt 2400 ]; do  # 3 秒 × 2400 ＝ 最大 2 時間で諦める
      sleep 3
      if [ "$(background_count)" -eq 0 ]; then
        report "○"
        break
      fi
      tries=$((tries + 1))
    done
  ) >/dev/null 2>&1 &
}

[ -n "$task_id" ] && track_background_shell "$task_id"

if [ "$(background_count)" -gt 0 ]; then
  report "●"
  start_watcher
else
  report "○"
fi

exit 0
