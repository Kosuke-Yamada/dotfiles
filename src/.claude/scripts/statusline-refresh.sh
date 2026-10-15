#!/usr/bin/env bash

# Claude Code SessionStart フック: 使用状況 API から最新のレート制限を取得し、
# statusline 用キャッシュを更新する。
# statusline.sh は入力 JSON に rate_limits が無い場合 (起動直後など) に
# このキャッシュへフォールバックして表示する。

set -u

CACHE_DIR="${HOME}/.claude/cache"
CACHE_FILE="${CACHE_DIR}/statusline-usage.json"
# 次に API を叩いてよい時刻 (epoch 秒)。全セッションで共有する
NEXT_ATTEMPT_FILE="${CACHE_DIR}/statusline-usage.next-attempt"
LOCK_DIR="${CACHE_DIR}/statusline-usage.lock"
CACHE_TTL=60
# 取得に失敗したら (429 など) この秒数は再試行しない。
# 失敗時に待たないと、全セッションが描画のたびに API を叩き続けて 429 が解けなくなる
FAILURE_BACKOFF=300
# curl の --max-time より十分長くとる (これより古いロックは異常終了の残骸とみなす)
LOCK_STALE_AFTER=30

now=$(date +%s)

# 前回の取得から TTL 以内なら取得しない (全セッション共有の現在時刻ベース判定)
# 取得時刻はキャッシュ JSON 内の _fetched_at で管理する
fetched_at=$(jq -r '._fetched_at // 0' "$CACHE_FILE" 2>/dev/null)
case "$fetched_at" in ''|*[!0-9]*) fetched_at=0 ;; esac
[ $(( now - fetched_at )) -lt "$CACHE_TTL" ] && exit 0

next_attempt=$(cat "$NEXT_ATTEMPT_FILE" 2>/dev/null)
case "$next_attempt" in ''|*[!0-9]*) next_attempt=0 ;; esac
[ "$now" -lt "$next_attempt" ] && exit 0

mkdir -p "$CACHE_DIR"

# 同時に複数セッションから取得しないようにロックする
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || echo "$now")
  [ $(( now - lock_mtime )) -lt "$LOCK_STALE_AFTER" ] && exit 0
  rmdir "$LOCK_DIR" 2>/dev/null
  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# 失敗した場合に備え、先にバックオフ後の時刻を書いておく (成功したら下で TTL 基準に戻す)
printf '%s' $(( now + FAILURE_BACKOFF )) > "$NEXT_ATTEMPT_FILE"

# OAuth トークンは Keychain から実行時に取得する (ファイルへは保存しない)
token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
[ -z "$token" ] && exit 0

# User-Agent が curl 既定値のままだと 429 (Rate limited) で弾かれるため Claude Code として名乗る
cc_version=$(claude --version 2>/dev/null | awk '{print $1}')

resp=$(curl -s --max-time 8 -w '\n%{http_code}' \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "User-Agent: claude-code/${cc_version:-unknown}" \
  "https://api.anthropic.com/api/oauth/usage") || exit 0

http_code=${resp##*$'\n'}
resp=${resp%$'\n'*}
[ "$http_code" = "200" ] || exit 0

# statusline.sh が読む rate_limits 互換形式へ変換する
# - _fetched_at は TTL 判定用の取得時刻 (statusline.sh のマージでも保持される)
# - モデル別週間上限 (Fable 等) は limits[] の scope.model から model_scoped へ写す
# - extra_usage は使用額・上限とも 0 の場合は表示不要なので落とす
cache=$(printf '%s' "$resp" | jq -c --argjson now "$now" '
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

# 変換に失敗した場合は既存キャッシュを壊さない。
# five_hour / seven_day が null なのはプランにその上限が無いことを表す正常な応答なので、
# そのまま書き込んで表示を消す (古い値を残すと誤った % が出続ける)
if [ -z "$cache" ] || [ "$cache" = "null" ]; then
  exit 0
fi

tmp="${CACHE_FILE}.tmp.$$"
printf '%s' "$cache" > "$tmp" && mv "$tmp" "$CACHE_FILE"
rm -f "$NEXT_ATTEMPT_FILE"

exit 0
