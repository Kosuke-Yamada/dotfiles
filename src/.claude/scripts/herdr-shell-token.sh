#!/bin/sh
# ==============================================================================
# herdr: Claude Code がシェルコマンドを実行中かを agents 一覧に表示する
# ==============================================================================
# Claude Code のフックから呼ばれ、シェルが動いている間だけ herdr へ ● を報告し、
# 止まったら ○ に戻す。herdr サイドバーの agents 一覧は config.toml の
# [ui.sidebar.agents] が稼働アイコンの直後にこの値を描画する。
#
# 使い方:
#   herdr-shell-token.sh running   # PreToolUse(Bash)
#   herdr-shell-token.sh idle      # PostToolUse(Bash)
#   herdr-shell-token.sh reset     # SessionStart / Stop / SessionEnd
#
# 状態はフックの回数ではなく実際のプロセスから判定する。Claude Code は Bash ツール
# 呼び出しごとに `zsh -c source ~/.claude/shell-snapshots/snapshot-*.sh …` を
# claude 本体の直下に生やすため、その本数がそのまま実行中のシェル数になる。
# 数を見るので、並列実行・サブエージェント経由・バックグラウンド実行を区別せず、
# 「まだ動いているのに ○ に戻る」取りこぼしが起きない。
#
# バックグラウンド実行（run_in_background）はコマンド起動直後に PostToolUse が
# 届くため、フックだけでは終了を知れない。シェルが残っている場合は見張りを 1 つ
# 切り離して起動し、消えた時点で ○ を報告させる。
#
# フックはツールの実行をブロックするため、失敗しても必ず終了コード 0 で返す。
# set -e は使わない（途中の失敗で非ゼロ終了させないため）。
# ------------------------------------------------------------------------------

action="${1:-reset}"

# フックの標準入力（JSON）は使わないが、読み捨てないと書き込み側がブロックし得る
cat >/dev/null 2>&1 || true

# herdr のペイン内でのみ動作する（HERDR_PANE_ID は herdr が各ペインへ渡す）
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

herdr_bin="${HERDR_BIN_PATH:-herdr}"
command -v "$herdr_bin" >/dev/null 2>&1 || exit 0

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

# 実行中のシェル本数。pgrep は自分のプロセスグループを除外してしまうため ps を使う
shell_count() {
  if [ -z "$claude_pid" ]; then
    echo 0
    return
  fi
  ps -ax -o ppid=,command= 2>/dev/null | awk -v cp="$claude_pid" '
    $1 == cp && /shell-snapshots\/snapshot-/ { n++ }
    END { print n + 0 }
  '
}

# シェルが消えるまで待って ○ に戻す見張り。ペインに 1 つだけ立てる
# （ロックはディレクトリ作成のアトミック性で取る）
start_watcher() {
  pane_key=$(printf '%s' "$HERDR_PANE_ID" | tr -c 'A-Za-z0-9_-' '_')
  lock="${TMPDIR:-/tmp}/herdr-shell-token-$pane_key.lock"
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
      if [ "$(shell_count)" -eq 0 ]; then
        report "○"
        break
      fi
      tries=$((tries + 1))
    done
  ) >/dev/null 2>&1 &
}

case "$action" in
  running)
    # ツール実行の直前。シェルはまだ生えていないことがあるので ps は見ない
    report "●"
    ;;
  *)
    # idle / reset: 実際に動いているシェルへ表示を合わせる
    if [ "$(shell_count)" -eq 0 ]; then
      report "○"
    else
      report "●"
      start_watcher
    fi
    ;;
esac

exit 0
