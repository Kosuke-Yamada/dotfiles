"""Merge the dotfiles-managed Codex config into ~/.codex/config.toml.

Tables are merged recursively and every other value in the source overwrites the
target, so keys that Codex writes on its own (projects, plugins, hooks.state, ...)
are kept as they are. tomlkit is used to preserve comments and formatting.

Usage: merge-config.py <source.toml> <target.toml>
"""

import sys
from pathlib import Path

import tomlkit
from tomlkit.items import Table
from tomlkit.toml_document import TOMLDocument


def merge(target: TOMLDocument | Table, source: TOMLDocument | Table) -> None:
    for key, value in source.items():
        current = target.get(key)
        if isinstance(value, Table) and isinstance(current, Table):
            merge(current, value)
        else:
            target[key] = value


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: merge-config.py <source.toml> <target.toml>")

    source_path, target_path = Path(sys.argv[1]), Path(sys.argv[2])
    source = tomlkit.parse(source_path.read_text())
    target = tomlkit.parse(target_path.read_text()) if target_path.exists() else tomlkit.document()

    before = tomlkit.dumps(target)
    merge(target, source)
    after = tomlkit.dumps(target)

    if after == before:
        print(f"変更なし: {target_path}")
        return

    target_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = target_path.with_name(f"{target_path.name}.tmp")
    tmp_path.write_text(after)
    tmp_path.replace(target_path)
    print(f"マージしました: {source_path} -> {target_path}")


if __name__ == "__main__":
    main()
