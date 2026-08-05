#!/usr/bin/env bash

# Claude Code statusline
# モデル名 / セッション(5h)使用率 / 週間使用率 / Fable 使用率と各リセットまでの残り時間を表示する

NC="\033[0m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
GRAY="\033[38;5;241m"

DIVIDER="${GRAY}∣${NC}"

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"' | sed -E 's/ \([^)]+\)$//')

color_for_pct() {
  local p=$1
  if [ "$p" -ge 80 ]; then
    printf "%s" "$RED"
  elif [ "$p" -ge 50 ]; then
    printf "%s" "$YELLOW"
  else
    printf "%s" "$GREEN"
  fi
}

# resets_at は epoch 秒 / ISO 8601 の両形式があり得るため吸収する
to_epoch() {
  local ts=$1
  [ -z "$ts" ] && return
  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    printf "%s" "$ts"
  else
    local clean
    clean=$(printf "%s" "$ts" | sed -E 's/\.[0-9]+//; s/Z$/+0000/; s/([+-][0-9]{2}):([0-9]{2})$/\1\2/')
    date -j -f "%Y-%m-%dT%H:%M:%S%z" "$clean" +%s 2>/dev/null
  fi
}

format_time_until() {
  local reset_epoch=$1
  [ -z "$reset_epoch" ] && return

  local now_epoch delta
  now_epoch=$(date +%s)
  delta=$(( reset_epoch - now_epoch ))
  [ "$delta" -le 0 ] && { printf "now"; return; }

  local days hours minutes
  days=$(( delta / 86400 ))
  hours=$(( (delta % 86400) / 3600 ))
  minutes=$(( (delta % 3600) / 60 ))

  if [ "$days" -gt 0 ]; then
    printf "%dd %dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf "%dh %dm" "$hours" "$minutes"
  else
    printf "%dm" "$minutes"
  fi
}

# ラベル・使用率・リセット時刻から 1 セグメントを組み立てる(使用率が無ければ何も出さない)
usage_segment() {
  local label=$1 pct=$2 reset_raw=$3
  [ -z "$pct" ] && return
  pct=${pct%.*}
  [ -z "$pct" ] && pct=0

  local color reset_epoch time_str reset_str=""
  color=$(color_for_pct "$pct")
  reset_epoch=$(to_epoch "$reset_raw")
  # リセット時刻を過ぎた値は古いキャッシュ由来 (ウィンドウは既にロールオーバー済み) なので表示しない
  if [ -n "$reset_epoch" ] && [ "$reset_epoch" -le "$(date +%s)" ]; then
    return
  fi
  time_str=$(format_time_until "$reset_epoch")
  [ -n "$time_str" ] && reset_str=$(printf " ${DIM}(%s)${NC}" "$time_str")

  printf " ${DIVIDER} ${DIM}%s${NC} ${color}%d%%${NC}%s" "$label" "$pct" "$reset_str"
}

# extra_usage のクレジット額はセント単位で渡される
fmt_cents() {
  awk -v c="$1" 'BEGIN{ d = c / 100; if (d == int(d)) printf "$%d", d; else printf "$%.2f", d }'
}

# クレジット消費 (Fable 等の overage 分) は金額で表示し、utilization で色分けする
credits_segment() {
  local used=$1 limit=$2 util=$3
  [ -z "$used" ] && return

  local used_str
  used_str=$(fmt_cents "$used")

  if [ -n "$limit" ]; then
    local pct=${util%.*}
    [ -z "$pct" ] && pct=0
    local color
    color=$(color_for_pct "$pct")
    printf " ${DIVIDER} ${DIM}Credits${NC} ${color}%s${NC}${DIM}/%s${NC}" "$used_str" "$(fmt_cents "$limit")"
  else
    printf " ${DIVIDER} ${DIM}Credits${NC} ${GREEN}%s${NC}" "$used_str"
  fi
}

# --- レート制限 (used_percentage / utilization はバージョン差異を吸収) ---
# 起動直後は入力に rate_limits が載らないため、SessionStart フック
# (statusline-refresh.sh) が書き出すキャッシュへフォールバックする
CACHE_FILE="${HOME}/.claude/cache/statusline-usage.json"

input_rl=$(echo "$input" | jq -c '.rate_limits // empty' 2>/dev/null)
[ "$input_rl" = "{}" ] && input_rl=""
cached_rl=$(cat "$CACHE_FILE" 2>/dev/null)

if [ -n "$input_rl" ]; then
  # 入力は five_hour / seven_day のみのことが多いため、入力に無いキー
  # (model_scoped / extra_usage 等) はキャッシュ側の値を残して統合する
  rate_limits=""
  if [ -n "$cached_rl" ]; then
    rate_limits=$(jq -cn --argjson cache "$cached_rl" --argjson live "$input_rl" '$cache * $live' 2>/dev/null)
  fi
  [ -z "$rate_limits" ] && rate_limits="$input_rl"

  # 次回起動時のフォールバック用にキャッシュへ反映する
  if [ "$rate_limits" != "$cached_rl" ]; then
    mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null
    tmp="${CACHE_FILE}.tmp.$$"
    printf '%s' "$rate_limits" > "$tmp" 2>/dev/null && mv "$tmp" "$CACHE_FILE" 2>/dev/null
  fi
else
  rate_limits="$cached_rl"
fi

session_pct=$(echo "$rate_limits" | jq -r '.five_hour // {} | (.used_percentage // .utilization) // empty' 2>/dev/null)
session_reset=$(echo "$rate_limits" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)

week_pct=$(echo "$rate_limits" | jq -r '.seven_day // {} | (.used_percentage // .utilization) // empty' 2>/dev/null)
week_reset=$(echo "$rate_limits" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

# Fable の週間上限は model_scoped 配列 (サーバー提供のモデル別ウィンドウ) から取得
fable_pct=$(echo "$rate_limits" | jq -r '[.model_scoped // [] | .[] | select(.display_name | test("fable"; "i"))] | .[0].utilization // empty' 2>/dev/null)
fable_reset=$(echo "$rate_limits" | jq -r '[.model_scoped // [] | .[] | select(.display_name | test("fable"; "i"))] | .[0].resets_at // empty' 2>/dev/null)

# Fable などクレジット消費型モデルの使用額は extra_usage (セント単位) に載る
extra_used=$(echo "$rate_limits" | jq -r '.extra_usage.used_credits // empty' 2>/dev/null)
extra_limit=$(echo "$rate_limits" | jq -r '.extra_usage.monthly_limit // empty' 2>/dev/null)
extra_util=$(echo "$rate_limits" | jq -r '.extra_usage.utilization // empty' 2>/dev/null)

line="${DIM}${model}${NC}"
line+=$(usage_segment "Session" "$session_pct" "$session_reset")
line+=$(usage_segment "Week" "$week_pct" "$week_reset")
line+=$(usage_segment "Fable" "$fable_pct" "$fable_reset")
line+=$(credits_segment "$extra_used" "$extra_limit" "$extra_util")

printf "%b" "$line"
