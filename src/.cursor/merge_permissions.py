"""Claude Code settings.json の permissions を cursor-agent cli-config.json にマージするスクリプト。

Bash(...) → Shell(...) の変換を行い、cli-config.json の permissions を更新する。
model, authInfo 等の既存設定は維持される。

Usage:
  python3 merge_permissions.py <claude_settings_json> <cursor_cli_config_json>
"""

import json
import re
import sys


def convert_permission(perm: str) -> str | None:
    """Claude Code の permission 記法を cursor-agent 形式に変換する。

    Bash(...) → Shell(...)
    WebFetch(...) → WebFetch(...) (そのまま)
    Write(...) → Edit(...) (cursor-agent では Edit)
    Read(...) → Read(...) (そのまま)
    """
    # Bash → Shell
    if perm.startswith("Bash("):
        inner = perm[5:-1]  # Bash(...) の中身
        return f"Shell({inner})"

    # Write → Edit (cursor-agent ではファイル書き込みは Edit)
    if perm.startswith("Write("):
        inner = perm[6:-1]
        return f"Edit({inner})"

    # WebFetch, Read はそのまま
    if perm.startswith(("WebFetch(", "Read(")):
        return perm

    return perm


def merge_permissions(claude_settings: dict, cursor_config: dict) -> dict:
    """Claude Code の permissions を cursor-agent の cli-config.json にマージする。"""
    claude_perms = claude_settings.get("permissions", {})
    cursor_perms = cursor_config.get("permissions", {"allow": [], "deny": []})

    # allow の変換
    allow = []
    for perm in claude_perms.get("allow", []):
        converted = convert_permission(perm)
        if converted:
            allow.append(converted)

    # deny の変換
    deny = []
    for perm in claude_perms.get("deny", []):
        converted = convert_permission(perm)
        if converted:
            deny.append(converted)

    # ask は cursor-agent にはないため、deny にも allow にも入れない
    # （cursor-agent のデフォルト承認フローで処理される）

    # 既存の cursor 固有の allow を維持（重複除去）
    existing_allow = set(cursor_perms.get("allow", []))
    for perm in allow:
        existing_allow.add(perm)

    cursor_config["permissions"] = {
        "allow": sorted(existing_allow),
        "deny": sorted(set(deny)),
    }

    # approvalMode を allowlist に設定（ask 相当の動作）
    cursor_config["approvalMode"] = "allowlist"

    return cursor_config


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <claude_settings.json> <cursor_cli-config.json>", file=sys.stderr)
        sys.exit(1)

    claude_path = sys.argv[1]
    cursor_path = sys.argv[2]

    with open(claude_path, encoding="utf-8") as f:
        claude_settings = json.load(f)

    with open(cursor_path, encoding="utf-8") as f:
        cursor_config = json.load(f)

    merged = merge_permissions(claude_settings, cursor_config)

    with open(cursor_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"permissions をマージしました: {cursor_path}")


if __name__ == "__main__":
    main()
