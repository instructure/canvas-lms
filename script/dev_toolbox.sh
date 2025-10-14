#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACK_FILE="${ROOT_DIR}/.canvas-stack"
STACK_HISTORY_FILE="${ROOT_DIR}/.canvas-stack.last"
TUI_DIR="${SCRIPT_DIR}/stack-manager"

STACK_SOURCE_VALUE="${STACK:-}"

read_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cat "$path"
  fi
}

DEFAULT_STACK=""
if [[ -n "$STACK_SOURCE_VALUE" ]]; then
  DEFAULT_STACK="$STACK_SOURCE_VALUE"
elif [[ -f "$STACK_FILE" ]]; then
  DEFAULT_STACK="$(read_file "$STACK_FILE")"
fi

if [[ -z "${DEFAULT_STACK}" || "${DEFAULT_STACK}" == "default" ]]; then
  if [[ -f "$STACK_HISTORY_FILE" ]]; then
    DEFAULT_STACK="$(read_file "$STACK_HISTORY_FILE")"
  fi
fi

if [[ -z "${DEFAULT_STACK}" ]]; then
  DEFAULT_STACK="default"
fi

STACK_HISTORY_VALUE="$(read_file "$STACK_HISTORY_FILE")"
STACK_PERSISTED_VALUE="$(read_file "$STACK_FILE")"

declare -a TUI_ARGS
TUI_ARGS=(--mode toolbox --default "$DEFAULT_STACK" --repo-root "$ROOT_DIR")

if [[ -n "$STACK_SOURCE_VALUE" ]]; then
  TUI_ARGS+=(--stack-value "$STACK_SOURCE_VALUE")
fi

if [[ -n "$STACK_HISTORY_FILE" ]]; then
  TUI_ARGS+=(--history-path "$STACK_HISTORY_FILE")
fi

if [[ -n "$STACK_HISTORY_VALUE" ]]; then
  TUI_ARGS+=(--history-value "$STACK_HISTORY_VALUE")
fi

if [[ -n "$STACK_FILE" ]]; then
  TUI_ARGS+=(--persisted-path "$STACK_FILE")
fi

if [[ -n "$STACK_PERSISTED_VALUE" ]]; then
  TUI_ARGS+=(--persisted-value "$STACK_PERSISTED_VALUE")
fi

if [[ ! -d "$TUI_DIR" ]]; then
  echo "Bubble Tea toolbox not found at $TUI_DIR" >&2
  exit 1
fi

if [[ ! -t 0 ]]; then
  echo "The developer toolbox requires an interactive terminal." >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "Go is required to run the developer toolbox. Please install Go 1.21+." >&2
  exit 1
fi

GOFLAGS_DEFAULT="-mod=readonly"
if [[ -n "${GOFLAGS:-}" ]]; then
  GOFLAGS_DEFAULT="${GOFLAGS} -mod=readonly"
fi

(cd "$TUI_DIR" && GOFLAGS="$GOFLAGS_DEFAULT" go run . "${TUI_ARGS[@]}")
