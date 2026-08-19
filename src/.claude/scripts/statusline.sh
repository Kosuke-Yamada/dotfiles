#!/usr/bin/env bash

# Claude Code statusline (2 行構成)
# 1 行目: モデル名 / セッション(5h)使用率 / 週間使用率 / Fable 使用率 / クレジット消費
#         (各使用率にはリセットまでの残り時間を併記)
# 2 行目: 現在の作業内容の要約 / 作業ディレクトリと git ブランチ

NC="\033[0m"
# Claude Code は statusline の各行を dim 属性 (\033[2m) で包んで描画するため、
# こちらで dim を重ねると二重に薄くなって読みにくい。
# 行頭で dim を解除 (\033[22m) し、フッターのヒント (shift+tab to cycle) と
# 同程度の明るさになるグレーを明示指定する。
UNDIM="\033[22m"
MUTED="\033[38;5;245m"
FAINT="\033[38;5;243m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

DIVIDER="${FAINT}∣${NC}"

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
  [ -n "$time_str" ] && reset_str=$(printf " ${MUTED}(%s)${NC}" "$time_str")

  printf " ${DIVIDER} ${MUTED}%s${NC} ${color}%d%%${NC}%s" "$label" "$pct" "$reset_str"
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
    printf " ${DIVIDER} ${MUTED}Credits${NC} ${color}%s${NC}${MUTED}/%s${NC}" "$used_str" "$(fmt_cents "$limit")"
  else
    printf " ${DIVIDER} ${MUTED}Credits${NC} ${GREEN}%s${NC}" "$used_str"
  fi
}

# 2 行目の前半: 現在の作業内容 (Claude Code が端末タイトルへ出しているタスク要約)。
# herdr のペインではタイトルバーが見えないため、ここに再掲する。
# 取得元は herdr の Socket API (自分のペイン)。herdr 外では何も表示しない。
# 使用率と行を分けたため既定では切り詰めない (端末幅を超えた分は Claude Code 側が切る)。
# STATUSLINE_TASK_MAX_LEN に正の値を設定した場合のみ、その文字数で切り詰める。
TASK_MAX_LEN=${STATUSLINE_TASK_MAX_LEN:-0}

task_segment() {
  [ -n "${HERDR_PANE_ID:-}" ] || return
  command -v herdr >/dev/null 2>&1 || return

  # 先頭のスピナー記号 (◐ ✳ など) は文字・数字が現れるまで削り、末尾の空白も落とす
  local task
  task=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null \
    | jq -r --argjson maxlen "$TASK_MAX_LEN" '
        .result.pane
        | (.terminal_title_stripped // .terminal_title // "")
        | sub("^[^\\p{L}\\p{N}]+"; "")
        | sub("\\s+$"; "")
        | if $maxlen > 0 then .[0:$maxlen] else . end
      ' 2>/dev/null)

  [ -n "$task" ] || return
  # 出力は最後に printf %b へ渡すため、タイトル中のバックスラッシュは解釈されないよう退避する
  printf "${FAINT}▸${NC} %s" "${task//\\/\\\\}"
}

# 2 行目の後半: 作業ディレクトリと git ブランチ。
# statusline の入力 JSON には branch が含まれないため git に問い合わせる
# (いずれも索引参照のみの軽量コマンド。ロックを取らないよう --no-optional-locks を付ける)
context_segment() {
  local cwd
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
  [ -n "$cwd" ] || return

  local root label branch="" dirty=""
  root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$root" ]; then
    # リポジトリ名 + リポジトリルートからの相対パス
    label="$(basename "$root")${cwd#"$root"}"
    # detached HEAD ではブランチ名が取れないため短縮コミットハッシュで代替する
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --quiet --short HEAD 2>/dev/null) \
      || branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    # 差分の件数は不要なので最初の 1 行が出た時点で打ち切る
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain --untracked-files=no 2>/dev/null | head -n 1)" ]; then
      dirty="*"
    fi
  else
    label="${cwd/#$HOME/~}"
  fi

  printf "${MUTED}%s${NC}" "$label"
  [ -n "$branch" ] && printf " ${DIVIDER} ${MUTED}%s%s${NC}" "$branch" "$dirty"
}

# --- レート制限 (used_percentage / utilization はバージョン差異を吸収) ---
# 起動直後は入力に rate_limits が載らないため、SessionStart フック
# (statusline-refresh.sh) が書き出すキャッシュへフォールバックする
# 注意: キャッシュの書き込みは statusline-refresh.sh のみが行う。
# ライブ入力の used_percentage は各セッションが最後に API 応答を受けた時点の値のため、
# アイドル中のセッションが古い値を共有キャッシュに書き込むと
# 他セッションの初回表示 (キャッシュフォールバック) が誤った % になる
CACHE_FILE="${HOME}/.claude/cache/statusline-usage.json"

input_rl=$(echo "$input" | jq -c '.rate_limits // empty' 2>/dev/null)
[ "$input_rl" = "{}" ] && input_rl=""
cached_rl=$(cat "$CACHE_FILE" 2>/dev/null)

if [ -n "$input_rl" ]; then
  # 入力は five_hour / seven_day のみのことが多いため、入力に無いキー
  # (model_scoped / extra_usage 等) はキャッシュ側の値で補完する (表示用のみ)
  rate_limits=""
  if [ -n "$cached_rl" ]; then
    rate_limits=$(jq -cn --argjson cache "$cached_rl" --argjson live "$input_rl" '$cache * $live' 2>/dev/null)
  fi
  [ -z "$rate_limits" ] && rate_limits="$input_rl"
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

# Claude Code は改行区切りで複数行を描画する (各行は端末幅で切り詰め)
usage_line="${MUTED}${model}${NC}"
usage_line+=$(usage_segment "Session" "$session_pct" "$session_reset")
usage_line+=$(usage_segment "Week" "$week_pct" "$week_reset")
usage_line+=$(usage_segment "Fable" "$fable_pct" "$fable_reset")
usage_line+=$(credits_segment "$extra_used" "$extra_limit" "$extra_util")

# 2 行目は作業内容と作業ディレクトリを区切り記号でつなぐ (片方だけでも成立させる)
info_line=$(task_segment)
context=$(context_segment)
if [ -n "$context" ]; then
  [ -n "$info_line" ] && info_line+=" ${DIVIDER} "
  info_line+="$context"
fi

# dim の解除は Text 単位 (= 行単位) に効くため、行ごとに付ける
lines="${UNDIM}${usage_line}"
# 2 行目が空になる場合は空行を残さず省略する
[ -n "$info_line" ] && lines+="\n${UNDIM}${info_line}"

printf "%b" "$lines"

# 取得データ (Fable / Credits 等) が古ければバックグラウンドで再取得する。
# 描画 (refreshInterval とイベント駆動) のたびに TTL を確認するため、
# セッション中も約 REFRESH_TTL 間隔で使用状況が更新され続ける (描画はブロックしない)
REFRESH_TTL=60
fetched_at=$(printf '%s' "$rate_limits" | jq -r '._fetched_at // 0' 2>/dev/null)
case "$fetched_at" in ''|*[!0-9]*) fetched_at=0 ;; esac
if [ $(( $(date +%s) - fetched_at )) -ge "$REFRESH_TTL" ]; then
  refresh_script="$(dirname "$0")/statusline-refresh.sh"
  [ -x "$refresh_script" ] && nohup "$refresh_script" >/dev/null 2>&1 &
fi
