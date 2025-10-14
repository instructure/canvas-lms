#!/usr/bin/env bash
set -euo pipefail

DEFAULT_STACK="default"
PROMPT_MESSAGE="Select docker stack"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_DIR="${SCRIPT_DIR}/stack-manager"
STACK_HISTORY_PATH="${STACK_HISTORY_PATH:-}"
STACK_PERSISTED_PATH="${STACK_PERSISTED_PATH:-}"
STACK_SOURCE_VALUE="${STACK_SOURCE_VALUE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --default)
      shift
      DEFAULT_STACK="${1:-default}"
      ;;
    --prompt)
      shift
      PROMPT_MESSAGE="${1:-Select docker stack}"
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: stack_manager.sh [--default STACK] [--prompt MESSAGE]

Interactive helper that prints the selected docker stack (default, arch, alpine).
When stdin is not a TTY it simply echoes the provided default.
USAGE
      exit 0
      ;;
  esac
  shift
done

readonly DEFAULT_STACK PROMPT_MESSAGE

OPTIONS=(default arch alpine)

is_valid() {
  local candidate="$1"
  for opt in "${OPTIONS[@]}"; do
    if [[ "$opt" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

normalize_input() {
  local input="${1,,}"
  case "$input" in
    1|d|def|default) echo "default" ;;
    2|ar|arch) echo "arch" ;;
    3|al|alp|alpine) echo "alpine" ;;
    *) echo "$input" ;;
  esac
}

read_file_value() {
  local path="$1"
  if [[ -n "$path" && -f "$path" ]]; then
    local value
    value="$(<"$path")"
    printf '%s' "$value"
  fi
}

STACK_HISTORY_VALUE="$(read_file_value "$STACK_HISTORY_PATH")"
STACK_PERSISTED_VALUE="$(read_file_value "$STACK_PERSISTED_PATH")"

declare -a TUI_ARGS
TUI_ARGS=(--mode stack --default "$DEFAULT_STACK" --prompt "$PROMPT_MESSAGE")

if [[ -n "$STACK_SOURCE_VALUE" ]]; then
  TUI_ARGS+=(--stack-value "$STACK_SOURCE_VALUE")
fi

if [[ -n "$STACK_HISTORY_PATH" ]]; then
  TUI_ARGS+=(--history-path "$STACK_HISTORY_PATH")
fi

if [[ -n "$STACK_HISTORY_VALUE" ]]; then
  TUI_ARGS+=(--history-value "$STACK_HISTORY_VALUE")
fi

if [[ -n "$STACK_PERSISTED_PATH" ]]; then
  TUI_ARGS+=(--persisted-path "$STACK_PERSISTED_PATH")
fi

if [[ -n "$STACK_PERSISTED_VALUE" ]]; then
  TUI_ARGS+=(--persisted-value "$STACK_PERSISTED_VALUE")
fi

run_bubbletea_selector() {
  if [[ ! -t 0 ]]; then
    return 1
  fi

  if ! command -v go >/dev/null 2>&1; then
    return 1
  fi

  if [[ ! -d "$TUI_DIR" ]]; then
    return 1
  fi

  local goflags="-mod=readonly"
  if [[ -n "${GOFLAGS:-}" ]]; then
    goflags="${GOFLAGS} -mod=readonly"
  fi

  (cd "$TUI_DIR" && GOFLAGS="$goflags" go run . "${TUI_ARGS[@]}")
}

fallback_prompt() {
  while true; do
    echo "$PROMPT_MESSAGE"
    idx=1
    for opt in "${OPTIONS[@]}"; do
      hint=""
      if [[ "$opt" == "$DEFAULT_STACK" ]]; then
        hint=" (default)"
      fi
      printf "  %d) %s%s\n" "$idx" "$opt" "$hint"
      idx=$((idx + 1))
    done

    read -r -p "Enter choice [default: ${DEFAULT_STACK}]: " REPLY
    if [[ -z "${REPLY}" ]]; then
      echo "$DEFAULT_STACK"
      return 0
    fi

    SELECTION="$(normalize_input "$REPLY")"
    if is_valid "$SELECTION"; then
      echo "$SELECTION"
      return 0
    fi

    echo "Invalid selection: '${REPLY}'. Please try again." >&2
  done
}

if ! is_valid "$DEFAULT_STACK"; then
  DEFAULT_STACK="default"
fi

if [[ ! -t 0 ]]; then
  echo "$DEFAULT_STACK"
  exit 0
fi

if run_bubbletea_selector; then
  exit 0
fi

fallback_prompt
