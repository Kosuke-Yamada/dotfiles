#!/usr/bin/env bash

# Claude Code SessionStart フック: 使用状況 API から最新のレート制限を取得し、
# statusline 用キャッシュを更新する。
# statusline.sh は入力 JSON に rate_limits が無い場合 (起動直後など) に
# このキャッシュへフォールバックして表示する。

set -u

CACHE_FILE="${HOME}/.claude/cache/statusline-usage.json"
CACHE_TTL=60

# 前回の取得から TTL 以内なら取得しない (全セッション共有の現在時刻ベース判定)
# 取得時刻はキャッシュ JSON 内の _fetched_at で管理する
fetched_at=$(jq -r '._fetched_at // 0' "$CACHE_FILE" 2>/dev/null)
case "$fetched_at" in ''|*[!0-9]*) fetched_at=0 ;; esac
[ $(( $(date +%s) - fetched_at )) -lt "$CACHE_TTL" ] && exit 0

# OAuth トークンは Keychain から実行時に取得する (ファイルへは保存しない)
token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
[ -z "$token" ] && exit 0

resp=$(curl -s --max-time 8 \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage") || exit 0

# statusline.sh が読む rate_limits 互換形式へ変換する
# - _fetched_at は TTL 判定用の取得時刻 (statusline.sh のマージでも保持される)
# - モデル別週間上限 (Fable 等) は limits[] の scope.model から model_scoped へ写す
# - extra_usage は使用額・上限とも 0 の場合は表示不要なので落とす
cache=$(printf '%s' "$resp" | jq -c --argjson now "$(date +%s)" '
  {
    _fetched_at: $now,
    five_hour: (.five_hour | if . == null then null else {utilization, resets_at} end),
    seven_day: (.seven_day | if . == null then null else {utilization, resets_at} end),
    model_scoped: [ (.limits // [])[]
      | select(.scope.model.display_name != null)
      | {display_name: .scope.model.display_name, utilization: .percent, resets_at} ],
    extra_usage: (.extra_usage
      | if . == null or ((.used_credits // 0) == 0 and (.monthly_limit // 0) == 0) then null
        else {used_credits, monthly_limit, utilization} end)
  }' 2>/dev/null)

# 変換に失敗した場合や認証エラー応答の場合は既存キャッシュを壊さない
if [ -z "$cache" ] || [ "$cache" = "null" ]; then
  exit 0
fi
if [ -z "$(printf '%s' "$cache" | jq -r '.five_hour // empty' 2>/dev/null)" ]; then
  exit 0
fi

mkdir -p "$(dirname "$CACHE_FILE")"
tmp="${CACHE_FILE}.tmp.$$"
printf '%s' "$cache" > "$tmp" && mv "$tmp" "$CACHE_FILE"

exit 0
