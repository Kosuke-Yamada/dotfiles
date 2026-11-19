#!/usr/bin/env bash
# Copilot CLI の permissionRequest フック: git コマンドを確認なしで許可する
# (Claude Code の Bash(git *)、Codex の git.rules 相当)。
# Copilot CLI には許可ルールを設定ファイルへ保存する仕組みがないため、フックで判定する。
# `git status && rm -rf ...` のように別コマンドを連結・埋め込みできる記号を含む場合は
# 何も出力せず、通常の確認フローに任せる。
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0
cmd=$(jq -r '.toolInput.command // empty')

case "$cmd" in
  *[\;\&\|\<\>\`\(\)]* | *'$'* | *$'\n'* | *$'\r'*) exit 0 ;;
esac

if [[ "$cmd" =~ ^[[:space:]]*git([[:space:]]|$) ]]; then
  echo '{"behavior":"allow"}'
fi
