#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="/usr/src/app"
APP_USER="${APP_USER:-docker}"
SECRETS_CREATED=0

ensure_secret() {
  local var_name="$1"
  local placeholder="${2:-}"
  local current_value="${!var_name-}"
  local store_dir="${APP_ROOT}/tmp/docker-secrets"
  local secret_file="${store_dir}/${var_name}"
  local had_secret_file=0

  if [[ -f "${secret_file}" ]]; then
    had_secret_file=1
  fi

  local generated
  generated="$(
    VAR_NAME="${var_name}" \
    PLACEHOLDER="${placeholder}" \
    CURRENT_VALUE="${current_value}" \
    STORE_DIR="${store_dir}" \
    APP_USER_NAME="${APP_USER}" \
    python3 <<'PY'
import os
import pathlib
import pwd
import secrets
import sys
import tempfile

var = os.environ["VAR_NAME"]
placeholder = os.environ.get("PLACEHOLDER", "")
current = os.environ.get("CURRENT_VALUE", "")
if current and (not placeholder or current != placeholder):
    print(current, end="")
    sys.exit(0)

store_dir = pathlib.Path(os.environ["STORE_DIR"])
store_dir.mkdir(parents=True, exist_ok=True)

app_user = os.environ.get("APP_USER_NAME", "")
pw_entry = None
if app_user:
    try:
        pw_entry = pwd.getpwnam(app_user)
    except KeyError:
        pw_entry = None

if pw_entry:
    try:
        os.chown(store_dir, pw_entry.pw_uid, pw_entry.pw_gid)
    except PermissionError:
        pass

secret_path = store_dir / var
if secret_path.exists():
    data = secret_path.read_text().strip()
    if data:
        print(data, end="")
        sys.exit(0)

value = secrets.token_hex(32)
with tempfile.NamedTemporaryFile(
    "w",
    dir=store_dir,
    prefix=f".{var}-",
    suffix=".tmp",
    delete=False,
) as tmp_file:
    tmp_file.write(value)
    tmp_name = tmp_file.name

tmp_path = pathlib.Path(tmp_name)
tmp_path.chmod(0o600)
try:
    os.replace(tmp_path, secret_path)
except FileNotFoundError:
    if not secret_path.exists():
        raise
finally:
    if tmp_path.exists():
        tmp_path.unlink()
os.chmod(secret_path, 0o600)

if pw_entry:
    try:
        os.chown(secret_path, pw_entry.pw_uid, pw_entry.pw_gid)
    except PermissionError:
        pass

print(value, end="")
PY
  )"

  export "${var_name}=${generated}"

  if [[ "${had_secret_file}" -eq 0 && -f "${secret_file}" ]]; then
    echo "Generated ${var_name} and stored at ${secret_file}"
    SECRETS_CREATED=1
  fi
}

ensure_encryption_keys() {
  ensure_secret "ENCRYPTION_KEY" "dev_local_encryption_key_please_change"
  ensure_secret "JWT_ENCRYPTION_KEY"
  export UPDATE_ENCRYPTION_KEY_HASH=1
}

set_nofile_limit() {
  # Raise the soft limit for open files while respecting the hard ceiling.
  local target="${CANVAS_NOFILE_LIMIT:-262144}"
  local hard_limit
  hard_limit="$(ulimit -Hn 2>/dev/null || true)"

  if [[ "$(id -u)" -eq 0 ]]; then
    if [[ -n "${hard_limit}" && "${hard_limit}" != "unlimited" ]]; then
      if (( target > hard_limit )); then
        ulimit -Hn "${target}" >/dev/null 2>&1 || true
        hard_limit="$(ulimit -Hn 2>/dev/null || true)"
      fi
    else
      ulimit -Hn "${target}" >/dev/null 2>&1 || true
      hard_limit="$(ulimit -Hn 2>/dev/null || true)"
    fi
  fi

  if [[ -n "${hard_limit}" && "${hard_limit}" != "unlimited" ]]; then
    if (( target > hard_limit )); then
      target="${hard_limit}"
    fi
  fi

  ulimit -Sn "${target}" >/dev/null 2>&1 || true
}

ensure_node_graceful_fs() {
  local require_arg="--require /usr/src/app/config/node/setup-graceful-fs.cjs"
  if [[ -z "${NODE_OPTIONS:-}" ]]; then
    export NODE_OPTIONS="${require_arg}"
  elif [[ "${NODE_OPTIONS}" != *"${require_arg}"* ]]; then
    export NODE_OPTIONS="${require_arg} ${NODE_OPTIONS}"
  fi
}

ensure_brandable_css() {
  local default_dir="${APP_ROOT}/public/dist/brandable_css/default"
  if [[ ! -d "${default_dir}" ]]; then
    echo "Generating brandable CSS assets..."
    bundle exec rake css:compile
  fi
}

reset_encryption_key_hash_if_needed() {
  if [[ "${UPDATE_ENCRYPTION_KEY_HASH:-0}" != "1" ]]; then
    return
  fi

  if [[ -z "${ENCRYPTION_KEY:-}" ]]; then
    echo "ENCRYPTION_KEY is unset; skipping reset_encryption_key_hash."
    return
  fi

  local sentinel="${APP_ROOT}/tmp/.encryption-key-hash"
  local current_key_hash
  current_key_hash="$(printf '%s' "${ENCRYPTION_KEY}" | sha256sum | awk '{print $1}')"

  if [[ -f "${sentinel}" ]]; then
    local cached
    cached="$(cat "${sentinel}")"
    if [[ "${cached}" == "${current_key_hash}" ]]; then
      return
    fi
  fi

  echo "Resetting encryption key hash to match current ENCRYPTION_KEY..."
  if bundle exec rails runner "CanvasSecurity.validate_encryption_key(true)"; then
    printf '%s\n' "${current_key_hash}" > "${sentinel}"
  else
    echo "Warning: CanvasSecurity.validate_encryption_key(true) failed; continuing without sentinel update." >&2
  fi
}

if [[ "$(id -u)" -eq 0 && "${APP_USER}" != "root" && "${CANVAS_ARCH_ENTRYPOINT_CHILD:-0}" != "1" ]]; then
  set_nofile_limit
  ensure_node_graceful_fs
  ensure_encryption_keys
  exec env \
    APP_USER="${APP_USER}" \
    USER="${APP_USER}" \
    HOME="/home/${APP_USER}" \
    PATH="${PATH}" \
    NODE_OPTIONS="${NODE_OPTIONS:-}" \
    CANVAS_ARCH_ENTRYPOINT_CHILD=1 \
    runuser -u "${APP_USER}" -- "$0" "$@"
fi

set_nofile_limit
ensure_node_graceful_fs
ensure_encryption_keys
echo "Canvas Arch entrypoint: soft nofile=$(ulimit -Sn 2>/dev/null || echo unknown) hard nofile=$(ulimit -Hn 2>/dev/null || echo unknown)"

if [[ -d "${APP_ROOT}" ]]; then
  cd "${APP_ROOT}"
  mkdir -p "${APP_ROOT}/tmp"

  if [[ -f "Gemfile" ]]; then
    echo "Ensuring Ruby gems are installed..."
    bundle check || bundle install
  fi

  if [[ -f "package.json" ]]; then
    echo "Ensuring JavaScript dependencies are installed..."
    yarn_mutex="file:${APP_ROOT}/tmp/yarn-mutex"
    yarn_args=(install --mutex "${yarn_mutex}")
    if [[ -f "yarn.lock" ]]; then
      yarn_args+=(--frozen-lockfile)
    fi
    if ! yarn "${yarn_args[@]}"; then
      echo "yarn install failed; clearing yarn cache and retrying..." >&2
      yarn cache clean >/dev/null 2>&1 || true
      yarn "${yarn_args[@]}"
    fi

    ensure_brandable_css
  fi
fi

reset_encryption_key_hash_if_needed

exec "$@"
