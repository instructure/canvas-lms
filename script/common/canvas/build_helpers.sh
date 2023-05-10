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
  _canvas_lms_track_with_log $DOCKER_COMMAND up -d web
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
  _canvas_lms_track_with_log run_command bundle install
  stop_spinner
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

function setup_docker_compose_override {
  message 'Setup override yaml and .env...'
  if [ -f "docker-compose.override.yml" ]; then
    message "docker-compose.override.yml already exists, skipping copy of default configuration!"
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
