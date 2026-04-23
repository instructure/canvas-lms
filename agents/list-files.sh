#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT" ls-files -co --exclude-standard | LC_ALL=C sort
else
  cd "$ROOT"
  find . -type f \
    -not -path './.git/*' \
    -not -path './agents/index/*' \
    | sed 's#^\./##' \
    | LC_ALL=C sort
fi