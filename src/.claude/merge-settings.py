"""Merge the dotfiles-managed Claude Code settings into ~/.claude/settings.json.

~/.claude/settings.json is a regular file so that what Claude Code, iTerm2 and
other tools write on each machine stays on that machine instead of the repo.

The merge is three-way against the source applied last time (the base file):
- objects are merged recursively and other source values overwrite the target
- list items written locally are kept after the source items
- keys and list items removed from the source since the base are removed

Usage: merge-settings.py <source.json> <target.json> <base.json>
"""

import json
import sys
from pathlib import Path
from typing import Any

MISSING = object()


def remove(value: Any, base: Any) -> Any:
    """Drop what the base introduced from value, returning MISSING when nothing is left."""
    if isinstance(value, dict) and isinstance(base, dict):
        result = dict(value)
        for key, base_value in base.items():
            if key in result:
                rest = remove(result[key], base_value)
                if rest is MISSING:
                    del result[key]
                else:
                    result[key] = rest
        return result if result else MISSING
    if isinstance(value, list) and isinstance(base, list):
        result = [item for item in value if item not in base]
        return result if result else MISSING
    return MISSING if value == base else value


def merge(target: Any, source: Any, base: Any) -> Any:
    if isinstance(target, dict) and isinstance(source, dict):
        base = base if isinstance(base, dict) else {}
        result = dict(target)
        for key in base.keys() - source.keys():
            if key in result:
                rest = remove(result[key], base[key])
                if rest is MISSING:
                    del result[key]
                else:
                    result[key] = rest
        for key, value in source.items():
            result[key] = merge(result[key], value, base.get(key)) if key in result else value
        return result
    if isinstance(target, list) and isinstance(source, list):
        base = base if isinstance(base, list) else []
        return source + [item for item in target if item not in source and item not in base]
    return source


def load(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as error:
        sys.exit(f"{path} の JSON を読み込めません: {error}")


def write(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_name(f"{path.name}.tmp")
    tmp_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    tmp_path.replace(path)


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit("usage: merge-settings.py <source.json> <target.json> <base.json>")

    source_path, target_path, base_path = map(Path, sys.argv[1:])
    source = load(source_path)
    target = load(target_path) if target_path.exists() else {}
    base = load(base_path) if base_path.exists() else {}

    merged = merge(target, source, base)
    if merged != target:
        write(target_path, merged)
        print(f"マージしました: {source_path} -> {target_path}")
    else:
        print(f"変更なし: {target_path}")
    write(base_path, source)


if __name__ == "__main__":
    main()
