#!/usr/bin/env python3
# <swiftbar.title>AI Usage</swiftbar.title>
# <swiftbar.desc>Claude Code / Codex / Copilot の月間使用量を表示する</swiftbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

"""SwiftBar プラグイン: Claude Code / Codex / Copilot の月間使用率を表示する。

- Claude Code: statusline-refresh.sh が書く ~/.claude/cache/statusline-usage.json の
  extra_usage (セント単位)。キャッシュが古ければ同スクリプトで更新する
  (TTL・失敗時バックオフ・ロックは同スクリプト側が持つ)
- Codex: ~/.codex/auth.json のトークンで使用状況 API を叩き、
  spend_control.individual_limit (ワークスペースの月間上限, credit 単位) を読む
- Copilot: gh api /copilot_internal/user の月間使用枠を読む (非公開 API)

macOS 同梱の /usr/bin/python3 (3.9) と、ログイン済みの gh CLI を使う。
"""

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, NamedTuple, Optional, Union

HOME = Path.home()
CLAUDE_CACHE = HOME / ".claude/cache/statusline-usage.json"
CLAUDE_REFRESH = HOME / ".claude/scripts/statusline-refresh.sh"
CODEX_AUTH = HOME / ".codex/auth.json"
CODEX_CACHE = HOME / ".cache/aiusage/codex-usage.json"
COPILOT_CACHE = HOME / ".cache/aiusage/copilot-usage.json"
CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"

# SwiftBar の更新間隔 (5m) より短くして、毎回のメニュー描画で最新値を取りにいく
CLAUDE_REFRESH_AFTER = 240
# この秒数より古い値を表示しているときは経過時間を併記する
STALE_AFTER = 900
# 残りがこの割合を切ったら色を変える
WARN_REMAINING = 30
CRIT_REMAINING = 10

# SwiftBar から起動すると PATH が最小限のため、jq / claude を見つけられるようにする
EXTRA_PATH = ["/opt/homebrew/bin", "/usr/local/bin", str(HOME / ".local/bin")]


class Budget(NamedTuple):
    """月間クレジットの使用状況。金額は表示単位 (USD または credit) に換算済み。"""

    used: float
    limit: float
    unit: str  # "usd" | "credit"
    fetched_at: Optional[float]
    reset_at: Optional[float]
    overage_allowed: Optional[bool] = None


class Failure(NamedTuple):
    message: str


Result = Union[Budget, Failure]


# --- 解析 (純粋関数) ---------------------------------------------------------


def parse_claude(cache: dict) -> Result:
    extra = cache.get("extra_usage")
    if not isinstance(extra, dict) or not extra.get("monthly_limit"):
        return Failure("月間クレジットの上限が設定されていません")
    return Budget(
        used=float(extra.get("used_credits") or 0) / 100,
        limit=float(extra["monthly_limit"]) / 100,
        unit="usd",
        fetched_at=cache.get("_fetched_at"),
        reset_at=None,
    )


def parse_codex(resp: dict, fetched_at: Optional[float]) -> Result:
    limit = ((resp.get("spend_control") or {}).get("individual_limit")) or None
    if not isinstance(limit, dict) or limit.get("limit") is None:
        return Failure("月間クレジットの上限が設定されていません")
    return Budget(
        used=float(limit.get("used") or 0),
        limit=float(limit["limit"]),
        unit=str(limit.get("unit") or "credit"),
        fetched_at=fetched_at,
        reset_at=limit.get("reset_at"),
    )


def parse_copilot(response: dict[str, object], fetched_at: Optional[float]) -> Result:
    snapshots = response.get("quota_snapshots")
    if not isinstance(snapshots, dict):
        return Failure("Copilot の使用枠を取得できません")
    quota = snapshots.get("premium_interactions")
    if not isinstance(quota, dict):
        return Failure("Copilot の月間使用枠がありません")
    if quota.get("unlimited"):
        return Failure("Copilot の月間使用枠は無制限です")
    try:
        return copilot_budget(quota, response.get("quota_reset_date_utc") or response.get("quota_reset_date"), fetched_at)
    except (ValueError, TypeError) as error:
        return Failure(f"Copilot の使用量データが不正です: {error}")


def copilot_budget(quota: dict[str, object], reset: object, fetched_at: Optional[float]) -> Budget:
    limit = quota.get("entitlement")
    available = quota.get("remaining")
    if not isinstance(limit, (int, float)) or limit <= 0:
        raise ValueError("月間使用枠が正の数ではありません")
    if not isinstance(available, (int, float)) or not 0 <= available <= limit:
        raise ValueError("月間残量が使用枠の範囲外です")
    reset_at = None
    if isinstance(reset, str):
        reset_at = datetime.fromisoformat(reset.replace("Z", "+00:00")).replace(tzinfo=timezone.utc).timestamp()
    allowed = quota.get("overage_permitted")
    unit = "credit" if quota.get("token_based_billing") else "request"
    return Budget(float(limit - available), float(limit), unit, fetched_at, reset_at,
                  allowed if isinstance(allowed, bool) else None)


# --- 表示 (純粋関数) ---------------------------------------------------------


def remaining(b: Budget) -> float:
    return max(b.limit - b.used, 0.0)


def remaining_percent(b: Budget) -> float:
    return remaining(b) / b.limit * 100 if b.limit > 0 else 0.0


def used_percent(b: Budget) -> float:
    return 100 - remaining_percent(b)


def fmt_amount(value: float, unit: str, compact: bool = False) -> str:
    if unit == "usd":
        return f"${value:,.0f}" if compact else f"${value:,.2f}"
    if compact and value >= 1000:
        return f"{value / 1000:.1f}k"
    return f"{value:,.0f}"


def fmt_duration(seconds: float) -> str:
    s = int(seconds)
    days, hours, minutes = s // 86400, s % 86400 // 3600, s % 3600 // 60
    if days:
        return f"{days}日{hours}時間"
    if hours:
        return f"{hours}時間{minutes}分"
    return f"{minutes}分"


def color_for(b: Budget) -> Optional[str]:
    pct = remaining_percent(b)
    if pct < CRIT_REMAINING:
        return "#e5484d"
    if pct < WARN_REMAINING:
        return "#f5a524"
    return None


def title_segment(label: str, r: Result) -> str:
    if isinstance(r, Failure):
        return f"{label}-"
    return f"{label}{used_percent(r):.0f}%"


def detail_lines(name: str, r: Result, now: float) -> list:
    if isinstance(r, Failure):
        return [name, f"--{r.message} | color=#e5484d"]

    unit_suffix = "" if r.unit == "usd" else f" {r.unit}"
    color = color_for(r)
    color_param = f" | color={color}" if color else ""
    lines = [
        name,
        f"--使用 {fmt_amount(r.used, r.unit)}{unit_suffix} ({used_percent(r):.0f}%){color_param}",
        f"--残り {fmt_amount(remaining(r), r.unit)} / {fmt_amount(r.limit, r.unit)}{unit_suffix}",
    ]
    if r.reset_at:
        reset = datetime.fromtimestamp(r.reset_at).strftime("%m/%d %H:%M")
        lines.append(f"--リセット {reset} (あと {fmt_duration(max(r.reset_at - now, 0))})")
    if r.overage_allowed is not None:
        permission = "許可（この枠で停止するとは限りません）" if r.overage_allowed else "不可"
        lines.append(f"--超過利用: {permission}")
    if r.fetched_at and now - r.fetched_at >= STALE_AFTER:
        lines.append(f"--{fmt_duration(now - r.fetched_at)}前の値 | color=#f5a524")
    return lines


def render(claude: Result, codex: Result, now: float, copilot: Optional[Result] = None) -> str:
    # SwiftBar は最初の "|" 以降をパラメータとして解釈するため、区切りに "|" は使えない
    title = f"{title_segment('CC', claude)} {title_segment('CX', codex)}"
    if copilot is not None:
        title += f" {title_segment('CP', copilot)}"
    warn = [c for c in (claude, codex, copilot) if isinstance(c, Budget) and color_for(c)]
    title_color = f" color={color_for(warn[0])}" if warn else ""
    lines = [
        f"{title} | font=Menlo size=12{title_color}",
        "---",
        "月間クレジット",
        *detail_lines("Claude Code", claude, now),
        *detail_lines("Codex", codex, now),
        *(detail_lines("GitHub Copilot", copilot, now) if copilot is not None else []),
        "---",
        "今すぐ更新 | refresh=true",
    ]
    return "\n".join(lines)


# --- 取得 (副作用あり) -------------------------------------------------------


def read_json(path: Path) -> dict:
    with path.open() as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path} が JSON オブジェクトではありません")
    return data


def child_env() -> dict:
    env = dict(os.environ)
    env["PATH"] = ":".join([*EXTRA_PATH, env.get("PATH", "/usr/bin:/bin")])
    return env


def load_claude(now: float) -> Result:
    try:
        cache = read_json(CLAUDE_CACHE)
    except FileNotFoundError:
        cache = {}
    except (OSError, ValueError) as e:
        return Failure(f"キャッシュを読めません: {e}")

    if now - float(cache.get("_fetched_at") or 0) >= CLAUDE_REFRESH_AFTER and CLAUDE_REFRESH.exists():
        try:
            subprocess.run(["bash", str(CLAUDE_REFRESH)], env=child_env(), timeout=15, check=False)
            cache = read_json(CLAUDE_CACHE)
        except subprocess.TimeoutExpired:
            pass  # 更新に失敗しても手元のキャッシュで表示し、古さは detail_lines で示す
        except (OSError, ValueError) as e:
            return Failure(f"キャッシュを読めません: {e}")

    if not cache:
        return Failure(f"{CLAUDE_CACHE} がありません (Claude Code を一度起動してください)")
    return parse_claude(cache)


def fetch_codex_usage() -> dict:
    auth = read_json(CODEX_AUTH)
    tokens = auth.get("tokens") or {}
    if not tokens.get("access_token"):
        raise RuntimeError("Codex に ChatGPT アカウントでログインしていません")
    req = urllib.request.Request(
        CODEX_USAGE_URL,
        headers={
            "Authorization": f"Bearer {tokens['access_token']}",
            "ChatGPT-Account-Id": str(tokens.get("account_id") or ""),
            "User-Agent": "codex_cli_rs",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            data = json.load(res)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            raise RuntimeError("トークンの期限切れ (Codex を起動すると更新されます)") from e
        raise RuntimeError(f"使用状況 API が HTTP {e.code} を返しました") from e
    if not isinstance(data, dict):
        raise RuntimeError("使用状況 API の応答が JSON オブジェクトではありません")
    return data


def load_codex(now: float, fetch: Callable[[], dict] = fetch_codex_usage) -> Result:
    try:
        resp = fetch()
        CODEX_CACHE.parent.mkdir(parents=True, exist_ok=True)
        tmp = CODEX_CACHE.with_suffix(f".tmp.{os.getpid()}")
        tmp.write_text(json.dumps({"_fetched_at": now, "response": resp}))
        tmp.replace(CODEX_CACHE)
        return parse_codex(resp, now)
    except (OSError, ValueError, RuntimeError, urllib.error.URLError) as e:
        error = str(e)

    # 取得に失敗したら前回の値を (古さを示して) 出す。前回値も無ければエラーを出す
    try:
        cached = read_json(CODEX_CACHE)
        return parse_codex(cached.get("response") or {}, cached.get("_fetched_at"))
    except (OSError, ValueError):
        return Failure(error)


def fetch_copilot_usage() -> dict[str, object]:
    # gh に認証を任せ、トークンを別ファイルへ複製しない。
    completed = subprocess.run(["gh", "api", "/copilot_internal/user"], env=child_env(),
                               capture_output=True, text=True, timeout=15, check=False)
    if completed.returncode:
        raise RuntimeError(f"Copilot の取得に失敗しました (gh auth login を確認): {completed.stderr.strip()}")
    response = json.loads(completed.stdout)
    if not isinstance(response, dict):
        raise ValueError("Copilot API の応答が JSON オブジェクトではありません")
    return response


def load_copilot(now: float, fetch: Callable[[], dict[str, object]] = fetch_copilot_usage) -> Result:
    try:
        response = fetch()
        result = parse_copilot(response, now)
        if isinstance(result, Failure):
            return result
        COPILOT_CACHE.parent.mkdir(parents=True, exist_ok=True)
        temporary = COPILOT_CACHE.with_suffix(f".tmp.{os.getpid()}")
        temporary.write_text(json.dumps({"_fetched_at": now, "response": response}))
        temporary.replace(COPILOT_CACHE)
        return result
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        message = f"Copilot の使用量を取得できません: {error}"
    try:
        cached = read_json(COPILOT_CACHE)
        return parse_copilot(cached.get("response") or {}, cached.get("_fetched_at"))
    except (OSError, ValueError):
        return Failure(message)


def main() -> int:
    now = time.time()
    print(render(load_claude(now), load_codex(now), now, load_copilot(now)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
