#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="/usr/src/app"

cd "${APP_ROOT}"

# Puma refuses to boot if this file lingers from a previous run
rm -f tmp/pids/server.pid

initial_setup_ran="false"
if [[ "${CANVAS_AUTO_INITIAL_SETUP:-true}" == "true" ]]; then
  echo "Checking whether the database needs initial setup..."
  if ! bundle exec rails runner 'exit ActiveRecord::Base.connection.table_exists?(:accounts) ? 0 : 1' >/dev/null 2>&1; then
    echo "Running database initial setup (db:initial_setup)..."
    bundle exec rake db:initial_setup
    initial_setup_ran="true"
  fi
fi

if [[ "${initial_setup_ran}" != "true" && "${CANVAS_AUTO_MIGRATE:-true}" == "true" ]]; then
  echo "Running database migrations..."
  bundle exec rake db:migrate
fi

ensure_dev_assets() {
  local sentinel="${APP_ROOT}/public/dist/.canvas-dev-assets-built"
  local sentinel_version="2"
  local needs_compile=0
  local needs_brand_defaults=0
  local -a missing_reasons=()
  local -a brand_missing_reasons=()

  register_missing() {
    missing_reasons+=("$1")
    needs_compile=1
  }

  register_brand_missing() {
    brand_missing_reasons+=("$1")
    needs_brand_defaults=1
  }

  ensure_file() {
    local path="$1"
    local label="${2:-}"
    if [[ ! -f "${path}" ]]; then
      register_missing "${label:-Missing file: ${path}}"
    fi
  }

  ensure_dir() {
    local path="$1"
    local label="${2:-}"
    if [[ ! -d "${path}" ]]; then
      register_missing "${label:-Missing directory: ${path}}"
    fi
  }

  ensure_glob() {
    local pattern="$1"
    local label="${2:-}"
    if ! compgen -G "${pattern}" >/dev/null 2>&1; then
      register_missing "${label:-No matches for: ${pattern}}"
    fi
  }

  if [[ "${CANVAS_FORCE_ASSET_COMPILE:-false}" == "true" ]]; then
    register_missing "Forced by CANVAS_FORCE_ASSET_COMPILE"
  fi

  if [[ -f "${sentinel}" ]]; then
    if ! grep -q "version=${sentinel_version}" "${sentinel}" 2>/dev/null; then
      register_missing "Sentinel out-of-date (expected version ${sentinel_version})"
    fi
  else
    register_missing "Sentinel missing"
  fi

  ensure_file "${APP_ROOT}/public/dist/rev-manifest.json" "Missing rev-manifest (run gulp rev)"
  ensure_file "${APP_ROOT}/public/dist/brandable_css/brandable_css_handlebars_index.json" \
    "Missing brandable CSS index"
  ensure_dir "${APP_ROOT}/public/dist/brandable_css/new_styles_normal_contrast" \
    "Missing brandable CSS variant directory"
  ensure_glob "${APP_ROOT}/public/dist/brandable_css/new_styles_normal_contrast/bundles/*.css" \
    "Missing compiled brandable CSS bundles"

  ensure_glob "${APP_ROOT}/public/dist/timezone/en_US"*.js \
    "Missing timezone data (en_US)"

  ensure_glob "${APP_ROOT}/public/dist/fonts/instructure_icons/Line/InstructureIcons-Line"*.woff \
    "Missing Instructure Line icon font (.woff)"
  ensure_glob "${APP_ROOT}/public/dist/fonts/instructure_icons/Line/InstructureIcons-Line"*.woff2 \
    "Missing Instructure Line icon font (.woff2)"
  ensure_glob "${APP_ROOT}/public/dist/fonts/lato/extended/Lato-"*.woff2 \
    "Missing Lato extended fonts (.woff2)"

  ensure_glob "${APP_ROOT}/public/dist/images/canvas_logomark_only@2x"*.png \
    "Missing Canvas logomark image"
  ensure_glob "${APP_ROOT}/public/dist/images/footer-logo@2x"*.png \
    "Missing footer logo image"

  local default_brand_dir="${APP_ROOT}/public/dist/brandable_css/default"
  if [[ ! -d "${default_brand_dir}" ]]; then
    register_brand_missing "Missing default brand directory (${default_brand_dir})"
  fi

  check_default_glob() {
    local pattern="$1"
    local label="${2:-}"
    if ! compgen -G "${pattern}" >/dev/null 2>&1; then
      register_brand_missing "${label:-No matches for: ${pattern}}"
    fi
  }

  check_default_file() {
    local path="$1"
    local label="${2:-}"
    if [[ ! -f "${path}" ]]; then
      register_brand_missing "${label:-Missing default brand asset: ${path}}"
    fi
  }

  check_default_glob "${default_brand_dir}/variables-"*".css" \
    "Missing default brand CSS variables"
  check_default_glob "${default_brand_dir}/variables-high_contrast-"*".css" \
    "Missing high contrast default brand CSS variables"
  check_default_glob "${default_brand_dir}/variables-"*".json" \
    "Missing default brand JSON variables"
  check_default_glob "${default_brand_dir}/variables-high_contrast-"*".json" \
    "Missing high contrast default brand JSON variables"
  check_default_glob "${default_brand_dir}/variables-"*".js" \
    "Missing default brand JS variables"
  check_default_glob "${default_brand_dir}/variables-high_contrast-"*".js" \
    "Missing high contrast default brand JS variables"

  check_default_file "${default_brand_dir}/images/mobile-global-nav-logo.svg"
  check_default_file "${default_brand_dir}/images/canvas_logomark_only@2x.png"
  check_default_file "${default_brand_dir}/images/favicon.ico"
  check_default_file "${default_brand_dir}/images/apple-touch-icon.png"
  check_default_file "${default_brand_dir}/images/windows-tile.png"
  check_default_file "${default_brand_dir}/images/windows-tile-wide.png"
  check_default_file "${default_brand_dir}/images/login/canvas-logo.svg"

  local wrote_sentinel=0

  if [[ "${needs_compile}" -eq 1 ]]; then
    if [[ ${#missing_reasons[@]} -gt 0 ]]; then
      echo "Compiling Canvas assets for development; reasons:"
      for reason in "${missing_reasons[@]}"; do
        echo "  - ${reason}"
      done
    else
      echo "Compiling Canvas assets for development (this may take several minutes)..."
    fi
    bundle exec rake canvas:compile_assets_dev
    mkdir -p "$(dirname "${sentinel}")"
    {
      echo "version=${sentinel_version}"
      echo "built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    } > "${sentinel}"
    wrote_sentinel=1
  else
    echo "Canvas assets already present; skipping compilation."
  fi

  if [[ "${needs_brand_defaults}" -eq 1 ]]; then
    if [[ ${#brand_missing_reasons[@]} -gt 0 ]]; then
      echo "Ensuring default brand assets; reasons:"
      for reason in "${brand_missing_reasons[@]}"; do
        echo "  - ${reason}"
      done
    fi
    sync_default_brand_assets
    if [[ "${wrote_sentinel}" -eq 0 ]]; then
      mkdir -p "$(dirname "${sentinel}")"
      {
        echo "version=${sentinel_version}"
        echo "built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      } > "${sentinel}"
    fi
  fi

  sync_timezone_assets
}

sync_default_brand_assets() {
  local default_brand_dir="${APP_ROOT}/public/dist/brandable_css/default"
  local -a assets=(
    "images/mobile-global-nav-logo.svg"
    "images/canvas_logomark_only@2x.png"
    "images/favicon.ico"
    "images/apple-touch-icon.png"
    "images/windows-tile.png"
    "images/windows-tile-wide.png"
    "images/login/canvas-logo.svg"
  )

  echo "Generating default brand variable files..."
  mkdir -p "${default_brand_dir}"
  if ! DISABLE_SPRING=1 bundle exec rails runner 'BrandableCSS.save_default_files!'; then
    echo "Rails runner failed while generating default brand files; falling back to css:compile..."
    DISABLE_SPRING=1 bundle exec rake css:compile
  fi

  for asset in "${assets[@]}"; do
    local source="${APP_ROOT}/public/${asset}"
    local relative="${asset}"
    if [[ "${relative}" == images/* ]]; then
      relative="${relative#images/}"
    fi
    if [[ ! -f "${source}" ]]; then
      echo "Warning: default asset source not found: ${source}"
      continue
    fi
    install -D -m 0644 "${source}" "${default_brand_dir}/${relative}"
    if [[ "${relative}" != "${asset}" ]]; then
      install -D -m 0644 "${source}" "${default_brand_dir}/${asset}"
    fi

    if [[ ! -f "${default_brand_dir}/${relative}" ]]; then
      echo "Warning: expected default asset missing after copy: ${default_brand_dir}/${relative}"
    fi
  done
}

sync_timezone_assets() {
  local dist_dir="${APP_ROOT}/public/dist/timezone"
  local legacy_dir="${APP_ROOT}/public/timezone"

  if [[ -d "${dist_dir}" ]]; then
    if [[ -L "${legacy_dir}" ]]; then
      local target
      target="$(readlink "${legacy_dir}")"
      if [[ "${target}" != "${dist_dir}" ]]; then
        rm -f "${legacy_dir}"
        ln -s "${dist_dir}" "${legacy_dir}"
      fi
    elif [[ -e "${legacy_dir}" && ! -d "${legacy_dir}" ]]; then
      echo "Warning: ${legacy_dir} exists but is not a directory or symlink; skipping timezone sync."
    elif [[ -d "${legacy_dir}" ]]; then
      cp -R "${dist_dir}/." "${legacy_dir}/"
    else
      ln -s "${dist_dir}" "${legacy_dir}"
    fi
  fi
}

if [[ "${CANVAS_AUTO_COMPILE_ASSETS:-true}" == "true" ]]; then
  ensure_dev_assets
fi

wait_for_webpack_manifest() {
  local manifest="${APP_ROOT}/public/dist/webpack-dev/mf-manifest.json"
  local timeout="${CANVAS_WEBPACK_BOOT_TIMEOUT:-120}"
  local waited=0

  if [[ "${CANVAS_SKIP_WEBPACK_WAIT:-0}" == "1" ]]; then
    return
  fi

  while [[ ! -f "${manifest}" && ${waited} -lt ${timeout} ]]; do
    if [[ ${waited} -eq 0 ]]; then
      echo "Waiting for webpack manifest at ${manifest}..."
    fi
    sleep 2
    waited=$((waited + 2))
  done

  if [[ -f "${manifest}" ]]; then
    echo "Webpack manifest found."
  else
    echo "Timed out waiting for webpack manifest after ${timeout}s; continuing anyway."
  fi
}

wait_for_webpack_manifest

PORT_VALUE="${PORT:-3000}"

echo "Starting Rails server on port ${PORT_VALUE}..."
exec bundle exec rails server -b 0.0.0.0 -p "${PORT_VALUE}"
