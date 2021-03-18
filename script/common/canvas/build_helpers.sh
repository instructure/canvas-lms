#!/bin/bash
source script/common.sh

function ensure_in_canvas_root_directory {
  if ! is_canvas_root; then
    echo "Please run from a Canvas root directory"
    exit 0
  fi
}

function is_canvas_root {
  CANVAS_IN_README=$(head -1 README.md 2>/dev/null | grep 'Canvas LMS')
  [[ "$CANVAS_IN_README" != "" ]] && is_git_dir
  return $?
}

function compile_assets {
  echo_console_and_log "  Compiling assets (css and js only, no docs or styleguide) ..."
  _canvas_lms_track_with_log docker-compose run --rm web bundle exec rake canvas:compile_assets_dev
}

function build_images {
  message 'Building docker images...'
  if [[ "$(uname)" == 'Linux' && -z "${CANVAS_SKIP_DOCKER_USERMOD:-}" ]]; then
    _canvas_lms_track docker-compose build --pull --build-arg USER_ID=$(id -u)
  else
    _canvas_lms_track docker-compose build --pull
  fi
}

function check_gemfile {
  if [[ -e Gemfile.lock ]]; then
    message \
'For historical reasons, the Canvas Gemfile.lock is not tracked by git. We may
need to remove it before we can install gems, to prevent conflicting dependency
errors.'
    confirm_command 'rm -f Gemfile.lock' || true
  fi

  # Fixes 'error while trying to write to `/usr/src/app/Gemfile.lock`'
  if ! docker-compose run --no-deps --rm web touch Gemfile.lock; then
    message \
"The 'docker' user is not allowed to write to Gemfile.lock. We need write
permissions so we can install gems."
    touch Gemfile.lock
    confirm_command 'chmod a+rw Gemfile.lock' || true
  fi
}

function build_assets {
  message "Building assets..."
  _canvas_lms_track docker-compose run --rm web ./script/install_assets.sh -c bundle
  _canvas_lms_track docker-compose run --rm web ./script/install_assets.sh -c yarn
  _canvas_lms_track docker-compose run --rm web ./script/install_assets.sh -c compile
}

function database_exists {
  docker-compose run --rm web bundle exec rails runner 'ActiveRecord::Base.connection' &> /dev/null
}

function create_db {
  if ! docker-compose run --no-deps --rm web touch db/structure.sql; then
    message \
"The 'docker' user is not allowed to write to db/structure.sql. We need write
permissions so we can run migrations."
    touch db/structure.sql
    confirm_command 'chmod a+rw db/structure.sql' || true
  fi

  if database_exists; then
    message \
'An existing database was found.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This script will destroy ALL EXISTING DATA if it continues
If you want to migrate the existing database, use docker_dev_update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    message 'About to run "bundle exec rake db:drop"'
    if [[ -z "${JENKINS}" ]]; then
      prompt "type NUKE in all caps: " nuked
      [[ ${nuked:-n} == 'NUKE' ]] || exit 1
    fi
    _canvas_lms_track docker-compose run --rm web bundle exec rake db:drop
  fi

  message "Creating new database"
  _canvas_lms_track docker-compose run --rm web \
    bundle exec rake db:create
  # initial_setup runs db:migrate for development
  _canvas_lms_track docker-compose run -e TELEMETRY_OPT_IN --rm web \
    bundle exec rake db:initial_setup
  # Rails db:migrate only runs on development by default
  # https://discuss.rubyonrails.org/t/db-drop-create-migrate-behavior-with-rails-env-development/74435
  _canvas_lms_track docker-compose run --rm web \
    bundle exec rake db:migrate RAILS_ENV=test
}


function bundle_install {
  echo_console_and_log "  Installing gems (bundle install) ..."
  rm -f Gemfile.lock* >/dev/null 2>&1
  _canvas_lms_track_with_log docker-compose run --rm web bundle install
}

function bundle_install_with_check {
  echo_console_and_log "  Checking your gems (bundle check) ..."
  if _canvas_lms_track_with_log docker-compose run --rm web bundle check ; then
    echo_console_and_log "  Gems are up to date, no need to bundle install ..."
  else
    bundle_install
  fi
}

function rake_db_migrate_dev_and_test {
  echo_console_and_log "  Migrating development DB ..."
  _canvas_lms_track_with_log docker-compose run --rm web bundle exec rake db:migrate RAILS_ENV=development
  echo_console_and_log "  Migrating test DB ..."
  _canvas_lms_track_with_log docker-compose run --rm web bundle exec rake db:migrate RAILS_ENV=test
}

function install_node_packages {
  echo_console_and_log "  Installing Node packages ..."
  _canvas_lms_track_with_log docker-compose run --rm web bundle exec rake js:yarn_install
}

function copy_docker_config {
  message 'Copying Canvas docker configuration...'
  confirm_command 'cp docker-compose/config/*.yml config/' || true
}

function setup_docker_compose_override {
  message 'Setup override yaml and .env...'
    if [ -f "docker-compose.override.yml" ]; then
    message "docker-compose.override.yml exists, skipping copy of default configuration"
  else
    message "Copying default configuration from config/docker-compose.override.yml.example to docker-compose.override.yml"
    cp config/docker-compose.override.yml.example docker-compose.override.yml
  fi
  if [ -f ".env" ]; then
    prompt '.env file exists, would you like to reset it to default? [y/n]' confirm
    [[ ${confirm:-n} == 'y' ]] || return 0
  fi
  message "Setting up default .env configuration"
  echo -n "COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml" > .env
}
