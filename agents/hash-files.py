#!/usr/bin/env python3
"""Compute deterministic hashes for a list of repository files."""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from sys import stdin, stdout


@dataclass(frozen=True)
class FileHash:
    path: str
    size: int
    sha256: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="Relative file paths")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--stdin", action="store_true", help="Read paths from stdin")
    return parser.parse_args()


def read_paths(args: argparse.Namespace) -> list[str]:
    if args.stdin:
        return [line.strip() for line in stdin if line.strip()]
    if args.paths:
        return args.paths
    return []


def hash_file(path: Path) -> FileHash:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            size += len(chunk)
            digest.update(chunk)
    return FileHash(path=str(path), size=size, sha256=digest.hexdigest())


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    paths = sorted(set(read_paths(args)))

    results: list[dict[str, object]] = []
    for relative_path in paths:
        file_path = (root / relative_path).resolve()
        if not file_path.is_file():
            continue
        hashed = hash_file(file_path)
        results.append({
            "path": relative_path.replace("\\", "/"),
            "size": hashed.size,
            "sha256": hashed.sha256,
        })

    json.dump({"root": str(root), "files": results}, stdout, indent=2, sort_keys=True)
    stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())