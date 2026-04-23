#!/usr/bin/env python3
"""Build repository analysis indexes for the analysis agent."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


LANGUAGE_BY_EXTENSION = {
    ".py": "python",
    ".rb": "ruby",
    ".rake": "ruby",
    ".js": "javascript",
    ".jsx": "javascript",
    ".ts": "typescript",
    ".tsx": "typescript",
    ".go": "go",
    ".rs": "rust",
    ".java": "java",
    ".c": "c",
    ".h": "c",
    ".cc": "cpp",
    ".cpp": "cpp",
    ".hpp": "cpp",
    ".cs": "csharp",
    ".md": "markdown",
    ".yml": "yaml",
    ".yaml": "yaml",
    ".json": "json",
    ".sh": "shell",
}

SYMBOL_PATTERNS = {
    "python": [
        (re.compile(r"^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)"), "class"),
        (re.compile(r"^\s*(?:async\s+def|def)\s+([A-Za-z_][A-Za-z0-9_]*)"), "function"),
    ],
    "ruby": [
        (re.compile(r"^\s*class\s+([A-Za-z_][A-Za-z0-9_:]*)"), "class"),
        (re.compile(r"^\s*module\s+([A-Za-z_][A-Za-z0-9_:]*)"), "module"),
        (re.compile(r"^\s*def\s+([A-Za-z_][A-Za-z0-9_!?=]*)"), "method"),
    ],
    "javascript": [
        (re.compile(r"^\s*class\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "class"),
        (re.compile(r"^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "function"),
        (re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:async\s+)?\(?"), "variable"),
    ],
    "typescript": [
        (re.compile(r"^\s*class\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "class"),
        (re.compile(r"^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "function"),
        (re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:async\s+)?\(?"), "variable"),
        (re.compile(r"^\s*type\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "type"),
        (re.compile(r"^\s*interface\s+([A-Za-z_$][A-Za-z0-9_$]*)"), "interface"),
    ],
    "go": [
        (re.compile(r"^\s*func\s+(?:\([^)]+\)\s*)?([A-Za-z_][A-Za-z0-9_]*)"), "function"),
        (re.compile(r"^\s*type\s+([A-Za-z_][A-Za-z0-9_]*)\s+(?:struct|interface)"), "type"),
    ],
    "rust": [
        (re.compile(r"^\s*(?:pub\s+)?(?:struct|enum|trait)\s+([A-Za-z_][A-Za-z0-9_]*)"), "type"),
        (re.compile(r"^\s*(?:pub\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)"), "function"),
    ],
    "java": [
        (re.compile(r"^\s*(?:public\s+)?(?:class|interface|enum)\s+([A-Za-z_][A-Za-z0-9_]*)"), "type"),
    ],
    "csharp": [
        (re.compile(r"^\s*(?:public\s+)?(?:class|interface|struct|record)\s+([A-Za-z_][A-Za-z0-9_]*)"), "type"),
    ],
}


@dataclass(frozen=True)
class ManifestEntry:
    path: str
    size: int
    sha256: str
    extension: str
    language: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--out-dir", default=None, help="Directory for generated indexes")
    parser.add_argument("--max-symbol-bytes", type=int, default=250_000, help="Skip symbol extraction above this size")
    return parser.parse_args()


def run_list_files(root: Path) -> list[str]:
    script = root / "agents" / "list-files.sh"
    if script.exists():
        commands = [["bash", str(script), str(root)], [str(script), str(root)]]
        for command in commands:
            try:
                result = subprocess.run(command, check=True, capture_output=True, text=True)
            except (FileNotFoundError, OSError, subprocess.CalledProcessError):
                continue
            return [line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()]
    return collect_files(root)


def collect_files(root: Path) -> list[str]:
    files: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(root).as_posix()
        if relative.startswith(".git/") or relative.startswith("agents/index/"):
            continue
        files.append(relative)
    return sorted(files)


def hash_file(path: Path) -> tuple[int, str]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            size += len(chunk)
            digest.update(chunk)
    return size, digest.hexdigest()


def guess_language(relative_path: str) -> tuple[str, str]:
    extension = Path(relative_path).suffix.lower()
    return extension, LANGUAGE_BY_EXTENSION.get(extension, "unknown")


def build_manifest(root: Path, relative_paths: Iterable[str]) -> list[ManifestEntry]:
    entries: list[ManifestEntry] = []
    for relative_path in relative_paths:
        file_path = root / relative_path
        if not file_path.is_file():
            continue
        size, sha256 = hash_file(file_path)
        extension, language = guess_language(relative_path)
        entries.append(ManifestEntry(relative_path, size, sha256, extension, language))
    return entries


def build_folder_summary(entries: Iterable[ManifestEntry]) -> dict[str, dict[str, object]]:
    summary: dict[str, dict[str, object]] = defaultdict(lambda: {
        "file_count": 0,
        "total_bytes": 0,
        "languages": Counter(),
        "extensions": Counter(),
        "children": Counter(),
    })

    for entry in entries:
        path = Path(entry.path)
        folders = [Path(".")] + list(path.parents[:-1])
        for index, folder in enumerate(folders):
            key = "." if str(folder) == "." else folder.as_posix()
            bucket = summary[key]
            bucket["file_count"] = int(bucket["file_count"]) + 1
            bucket["total_bytes"] = int(bucket["total_bytes"]) + entry.size
            bucket["languages"][entry.language] += 1
            bucket["extensions"][entry.extension or ""] += 1
            child_name = path.parts[index] if index < len(path.parts) else path.name
            bucket["children"][child_name] += 1

    output: dict[str, dict[str, object]] = {}
    for folder, bucket in summary.items():
        output[folder] = {
            "file_count": bucket["file_count"],
            "total_bytes": bucket["total_bytes"],
            "languages": dict(sorted(bucket["languages"].items())),
            "extensions": dict(sorted(bucket["extensions"].items())),
            "notable_children": [
                name for name, _count in bucket["children"].most_common(10)
            ],
        }
    return dict(sorted(output.items()))


def extract_symbols(root: Path, entries: Iterable[ManifestEntry], max_symbol_bytes: int) -> dict[str, list[dict[str, object]]]:
    symbols: dict[str, list[dict[str, object]]] = defaultdict(list)
    for entry in entries:
        if entry.language == "unknown" or entry.size > max_symbol_bytes:
            continue
        patterns = SYMBOL_PATTERNS.get(entry.language, [])
        if not patterns:
            continue
        file_path = root / entry.path
        try:
            text = file_path.read_text(encoding="utf-8", errors="ignore").splitlines()
        except OSError:
            continue
        for line_number, line in enumerate(text, start=1):
            for regex, kind in patterns:
                match = regex.match(line)
                if not match:
                    continue
                symbol_name = match.group(1)
                symbols[symbol_name].append({
                    "path": entry.path,
                    "line": line_number,
                    "kind": kind,
                    "language": entry.language,
                })
    return dict(sorted((name, sorted(locations, key=lambda item: (item["path"], item["line"]))) for name, locations in symbols.items()))


def manifest_fingerprint(entries: Iterable[ManifestEntry]) -> str:
    digest = hashlib.sha256()
    for entry in entries:
        digest.update(entry.path.encode("utf-8"))
        digest.update(b"\0")
        digest.update(entry.sha256.encode("utf-8"))
        digest.update(b"\0")
        digest.update(str(entry.size).encode("utf-8"))
        digest.update(b"\0")
    return digest.hexdigest()


def write_json(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    out_dir = Path(args.out_dir).resolve() if args.out_dir else root / "agents" / "index"

    relative_paths = run_list_files(root)
    entries = build_manifest(root, relative_paths)
    folder_summary = build_folder_summary(entries)
    symbols = extract_symbols(root, entries, args.max_symbol_bytes)
    fingerprint = manifest_fingerprint(entries)

    write_json(out_dir / "manifest.json", {
        "root": str(root),
        "files": [entry.__dict__ for entry in entries],
    })
    write_json(out_dir / "folders.json", folder_summary)
    write_json(out_dir / "symbols.json", symbols)
    write_json(out_dir / "hashes.json", {
        "root": str(root),
        "files": [{"path": entry.path, "sha256": entry.sha256, "size": entry.size} for entry in entries],
    })
    write_json(out_dir / "state.json", {
        "root": str(root),
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "manifest_fingerprint": fingerprint,
        "file_count": len(entries),
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())