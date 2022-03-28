#!/bin/bash
source script/common/utils/common.sh

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
  start_spinner "Compiling assets (css and js only, no docs or styleguide)..."
  _canvas_lms_track_with_log run_command bundle exec rake canvas:compile_assets_dev
  stop_spinner
}

function build_images {
  start_spinner 'Building docker images...'
  if [[ -n "$JENKINS" ]]; then
    _canvas_lms_track_with_log docker-compose build --build-arg USER_ID=$(id -u)
  elif [[ "${OS:-}" == 'Linux' && -z "${CANVAS_SKIP_DOCKER_USERMOD:-}" ]]; then
    _canvas_lms_track_with_log docker-compose build --pull --build-arg USER_ID=$(id -u)
  else
    _canvas_lms_track_with_log $DOCKER_COMMAND build --pull
  fi
  stop_spinner
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
  if ! _canvas_lms_track_with_log $DOCKER_COMMAND run --no-deps --rm web touch Gemfile.lock; then
    message \
"The 'docker' user is not allowed to write to Gemfile.lock. We need write
permissions so we can install gems."
    touch Gemfile.lock
    confirm_command 'chmod a+rw Gemfile.lock' || true
  fi
}

function build_assets {
  message "Building assets..."
  start_spinner "> Bundle install..."
  _canvas_lms_track_with_log run_command ./script/install_assets.sh -c bundle
  stop_spinner
  start_spinner "> Yarn install...."
  _canvas_lms_track_with_log run_command ./script/install_assets.sh -c yarn
  stop_spinner
  start_spinner "> Compile assets...."
  _canvas_lms_track_with_log run_command ./script/install_assets.sh -c compile
  stop_spinner
}

function database_exists {
  run_command bundle exec rails runner 'ActiveRecord::Base.connection' &> /dev/null
}

function create_db {
  if ! _canvas_lms_track_with_log run_command touch db/structure.sql; then
    message \
"The 'docker' user is not allowed to write to db/structure.sql. We need write
permissions so we can run migrations."
    touch db/structure.sql
    confirm_command 'chmod a+rw db/structure.sql' || true
  fi

  start_spinner "Checking for existing db..."
  if database_exists; then
    stop_spinner
    message \
'An existing database was found.'
    if ! is_running_on_jenkins; then
      prompt "Do you want to drop and create new or migrate existing? [DROP/migrate] " dropped
    fi
    if [[ ${dropped:-migrate} == 'DROP' ]]; then
      message \
'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This script will destroy ALL EXISTING DATA if it continues
If you want to migrate the existing database, cancel now
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      message 'About to run "bundle exec rake db:drop"'
      start_spinner "Deleting db....."
      _canvas_lms_track_with_log run_command bundle exec rake db:drop
      stop_spinner
    fi
  fi
  stop_spinner
  if [[ ${dropped:-DROP} == 'DROP' ]]; then
    start_spinner "Creating new database...."
    _canvas_lms_track_with_log run_command bundle exec rake db:create
    stop_spinner
  fi
  # Rails db:migrate only runs on development by default
  # https://discuss.rubyonrails.org/t/db-drop-create-migrate-behavior-with-rails-env-development/74435
  start_spinner "Migrating (Development env)...."
  _canvas_lms_track_with_log run_command bundle exec rake db:migrate RAILS_ENV=development
  stop_spinner
  start_spinner "Migrating (Test env)...."
  _canvas_lms_track_with_log run_command bundle exec rake db:migrate RAILS_ENV=test
  stop_spinner
  [[ ${dropped:-DROP} == 'migrate' ]] || _canvas_lms_track run_command_tty bundle exec rake db:initial_setup
}

function bundle_install {
  start_spinner "  Installing gems (bundle install) ..."
  run_command bash -c 'rm -f Gemfile.lock* >/dev/null 2>&1'
  _canvas_lms_track_with_log run_command bundle install
  stop_spinner
}

function bundle_install_with_check {
  start_spinner "Checking your gems (bundle check)..."
  if _canvas_lms_track_with_log run_command bundle check ; then
    stop_spinner
    echo_console_and_log "  Gems are up to date, no need to bundle install ..."
  else
    stop_spinner
    bundle_install
  fi
}

function rake_db_migrate_dev_and_test {
  start_spinner "Migrating development DB..."
  _canvas_lms_track_with_log run_command bundle exec rake db:migrate RAILS_ENV=development
  stop_spinner
  start_spinner "Migrating test DB..."
  _canvas_lms_track_with_log run_command bundle exec rake db:migrate RAILS_ENV=test
  stop_spinner
}

function install_node_packages {
  start_spinner "Installing Node packages..."
  _canvas_lms_track_with_log run_command bundle exec rake js:yarn_install
  stop_spinner
}

function copy_docker_config {
  message 'Copying Canvas docker configuration...'
  confirm_command 'cp docker-compose/config/*.yml config/' || true
}

function copy_mutagen_override {
  message "Copying default configuration from docker-compose/mutagen/docker-compose.override.yml to docker-compose.override.yml"
  cp docker-compose/mutagen/docker-compose.override.yml docker-compose.override.yml
}

function setup_docker_compose_override {
  message 'Setup override yaml and .env...'
  if [ -f "docker-compose.override.yml" ]; then
    prompt 'docker-compose.override.yml already exists.
Would you like to copy docker-compose/mutagen/docker-compose.override.yml to docker-compose.override.yml? [y/n]' copy
    [[ ${copy:-y} == 'n' ]] || copy_mutagen_override
  else
    copy_mutagen_override
  fi

  if [ -f ".env" ]; then
    prompt '.env file exists, would you like to reset it to default? [y/n]' confirm
    [[ ${confirm:-n} == 'y' ]] || return 0
  fi
  message "Setting up default .env configuration"
  echo -n "COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml" > .env
}
