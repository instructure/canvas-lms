#!/bin/bash

# This file contains commonly used BASH functions for scripting in canvas-lms,
# particularly script/canvas_update and script/rebase_canvas_and_plugins . As such,
# *be careful* when you modify these functions as doing so will impact multiple
# scripts that likely aren't used or tested in continuous integration builds.

function create_log_file {
  if [ ! -f "$LOG" ]; then
    echo "" > "$LOG"
  fi
}

function echo_console_and_log {
  echo "$1" |tee -a "$LOG"
}

function print_results {
  exit_code=$?
  set +e

  if [ "${exit_code}" == "0" ]; then
    echo ""
    echo_console_and_log "  \o/ Success!"
  else
    echo ""
    echo_console_and_log "  /o\ Something went wrong. Check ${LOG} for details."
  fi

  exit ${exit_code}
}

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

function is_git_dir {
  [ "$(basename "$(git rev-parse --show-toplevel)")" == "$(basename "$(pwd)")" ]
}

# Parameter: the name of the script calling this function
function intro_message {
  script_name="$1"
  echo "Bringing Canvas up to date ..."
  echo "  Log file is $LOG"

  echo >>"$LOG"
  echo "-----------------------------" >>"$LOG"
  echo "$1 ($(date)):" >>"$LOG"
  echo "-----------------------------" >>"$LOG"
}

function bundle_install {
  echo_console_and_log "  Installing gems (bundle install) ..."
  rm -f Gemfile.lock* >/dev/null 2>&1
  run_command bundle install >>"$LOG" 2>&1
}

function bundle_install_with_check {
  echo_console_and_log "  Checking your gems (bundle check) ..."
  if run_command bundle check >>"$LOG" 2>&1 ; then
    echo_console_and_log "  Gems are up to date, no need to bundle install ..."
  else
    bundle_install
  fi
}

function rake_db_migrate_dev_and_test {
  echo_console_and_log "  Migrating development DB ..."
  run_command bundle exec rake db:migrate RAILS_ENV=development >>"$LOG" 2>&1
  echo_console_and_log "  Migrating test DB ..."
  run_command bundle exec rake db:migrate RAILS_ENV=test >>"$LOG" 2>&1
}

function install_node_packages {
  echo_console_and_log "  Installing Node packages ..."
  run_command bundle exec rake js:yarn_install >>"$LOG" 2>&1
}

function compile_assets {
  echo_console_and_log "  Compiling assets (css and js only, no docs or styleguide) ..."
  run_command bundle exec rake canvas:compile_assets_dev >>"$LOG" 2>&1
}

# If DOCKER var set true, run with docker-compose
function run_command {
  if [ "${DOCKER:-}" == 'y' ]; then
    docker-compose run --rm web "$@"
  else
    "$@"
  fi
}

function _canvas_lms_track {
  command="$@"
  if type _inst_telemetry >/dev/null 2>&1 &&  _canvas_lms_telemetry_enabled; then
    _inst_telemetry $command
  else
    $command
  fi
}

function _canvas_lms_telemetry_enabled() {
  if [[ ${TELEMETRY_OPT_IN-n} == 'y' ]];
  then
    return 0
  fi
  return 1
}

function prompt {
  read -r -p "$1 " "$2"
}

function message {
  echo ''
  echo "$BOLD> $*$NORMAL"
}

function confirm_command {
  if [ -z "${JENKINS-}" ]; then
    prompt "OK to run '$*'? [y/n]" confirm
    [[ ${confirm:-n} == 'y' ]] || return 1
  fi
  eval "$*"
}