#!/bin/sh
# ==============================================================================
# herdr: Claude Code がシェルコマンドを実行中かを agents 一覧に表示する
# ==============================================================================
# Claude Code の PreToolUse/PostToolUse フックから呼ばれ、Bash ツールの実行中だけ
# herdr へ ● を報告する。待機中は ○ に戻す。herdr サイドバーの agents 一覧は
# config.toml の [ui.sidebar.agents] で稼働アイコンの直後にこの値を描画する。
#
# 使い方: herdr-shell-token.sh <running|idle>
#
# フックはツールの実行をブロックするため、失敗しても必ず終了コード 0 で返す。
# ------------------------------------------------------------------------------

# フックの標準入力（JSON）は使わないが、読み捨てないと Claude Code 側が
# パイプ書き込みでブロックし得るため必ず消費する
cat >/dev/null 2>&1 || true

# herdr のペイン内でのみ動作する（HERDR_PANE_ID は herdr が各ペインへ渡す）
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

herdr_bin="${HERDR_BIN_PATH:-herdr}"
command -v "$herdr_bin" >/dev/null 2>&1 || exit 0

case "${1:-idle}" in
  running) mark="●" ;;  # シェル実行中（塗りつぶし）
  *)       mark="○" ;;  # 待機中（空白丸）
esac

# display-only メタデータなので、herdr 組み込みの claude 統合が持つ
# エージェント状態の報告権限とは競合しない。source は統合と分けておく
"$herdr_bin" pane report-metadata "$HERDR_PANE_ID" \
  --source claude-shell --token "shell=$mark" >/dev/null 2>&1 || true

exit 0
