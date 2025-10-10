#!/usr/bin/env bash
set -euo pipefail
cd /app

# --- Helpers ---
die() { echo "ERROR: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

ensure_bundler() {
  # Use the pinned version if present
  if ! bundle -v 2>/dev/null | grep -q "2.5.13"; then
    gem install bundler:2.5.13 || true
  fi
  # Register bundler-multilock plugin if missing (writes to ~/.bundle)
  if ! bundle plugin list 2>/dev/null | grep -q "bundler-multilock"; then
    bundle plugin install bundler-multilock
  fi
}

# The guide requires these configs; we generate safe defaults from envs.
# Production-specific values are written under 'production:' keys.
gen_configs() {
  mkdir -p config

  # database.yml (Production Start expects Postgres in prod)
  if [ ! -f config/database.yml ]; then
    [ -n "${DATABASE_URL:-}" ] || die "DATABASE_URL is required (postgres://user:pass@host:5432/canvas_production)."
    cat > config/database.yml <<YAML
production:
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch('DB_POOL', 20) %>
YAML
  fi

  # redis.yml — modern format uses 'url:' (old 'servers:' can break logins)
  if [ ! -f config/redis.yml ] && [ -n "${REDIS_URL:-}" ]; then
    cat > config/redis.yml <<YAML
production:
  url: <%= ENV['REDIS_URL'] %>
YAML
  fi

  # domain.yml — Canvas calls out domain/files_domain in Production Start
  if [ ! -f config/domain.yml ]; then
    cat > config/domain.yml <<YAML
production:
  domain: <%= ENV.fetch('CANVAS_DOMAIN', 'localhost') %>
  files_domain: <%= ENV.fetch('FILES_DOMAIN', '') %>
YAML
  fi

  # outgoing_mail.yml — strongly recommended for password resets
  if [ ! -f config/outgoing_mail.yml ] && [ -n "${SMTP_ADDRESS:-}" ]; then
    cat > config/outgoing_mail.yml <<YAML
production:
  address: <%= ENV['SMTP_ADDRESS'] %>
  port: <%= ENV.fetch('SMTP_PORT','587') %>
  user_name: <%= ENV['SMTP_USER'] %>
  password: <%= ENV['SMTP_PASSWORD'] %>
  authentication: <%= ENV.fetch('SMTP_AUTH','plain') %>
  domain: <%= ENV.fetch('SMTP_DOMAIN', ENV.fetch('CANVAS_DOMAIN','localhost')) %>
  enable_starttls_auto: <%= ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO','true') %>
YAML
  fi

  # security.yml — required secrets. If SECRET_KEY_BASE not provided, generate
  if [ ! -f config/security.yml ]; then
    if [ -z "${SECRET_KEY_BASE:-}" ]; then
      SECRET_KEY_BASE="$(ruby -e 'require "securerandom"; print SecureRandom.hex(64)')"
      export SECRET_KEY_BASE
    fi
    cat > config/security.yml <<YAML
production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
  encryption_key: <%= ENV.fetch('ENCRYPTION_KEY', ENV['SECRET_KEY_BASE']) %>
  oauth2_encryption_key: <%= ENV.fetch('OAUTH2_ENCRYPTION_KEY', ENV['SECRET_KEY_BASE']) %>
YAML
  fi

  # keep configs private
  chmod 400 config/*.yml 2>/dev/null || true
}

db_exists() {
  bundle exec ruby -e "require 'active_record'; require 'yaml'; require 'erb';
    conf=YAML.safe_load(ERB.new(File.read('config/database.yml')).result, aliases: true);
    ActiveRecord::Base.establish_connection(conf['production']);
    begin
      puts ActiveRecord::Base.connection.table_exists?('schema_migrations') ? 'yes' : 'no'
    rescue => e
      warn e
      puts 'no'
    end" | grep -q yes
}

initial_setup_if_needed() {
  # One-time destructive initializer. **DO NOT** re-run on existing DB.
  if [ "${RUN_INITIAL_SETUP:-true}" = "true" ] && ! db_exists; then
    echo ">> Running db:initial_setup (first boot schema + seed)..."
    # Admin bootstrap envs are recognized by Canvas tasks (per wiki)
    export CANVAS_LMS_ADMIN_EMAIL CANVAS_LMS_ADMIN_PASSWORD CANVAS_LMS_ACCOUNT_NAME CANVAS_LMS_STATS_COLLECTION
    RAILS_ENV=production bundle exec rake db:initial_setup
  fi
}

migrate_if_requested() {
  if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    echo ">> Running db:migrate..."
    RAILS_ENV=production bundle exec rake db:migrate
  fi
}

start_web() {
  # Canvas ships config/puma.rb; TLS terminated upstream by Dokploy/Traefik
  exec bundle exec puma -C config/puma.rb
}

start_worker() {
  # Background jobs with delayed_job
  exec RAILS_ENV=production script/delayed_job run
}

# --- flow ---
ensure_bundler
gen_configs
initial_setup_if_needed
migrate_if_requested

case "${1:-web}" in
  web)    start_web ;;
  worker) start_worker ;;
  *) echo "Unknown ROLE '$1' (expected 'web' or 'worker')" >&2; exit 2 ;;
esac
