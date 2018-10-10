#!/bin/bash

# This file contains commonly used BASH functions for scripting in canvas-lms,
# particularly script/canvas_update and script/prepare/prepare . As such,
# *be careful* when you modify these functions as doing so will impact multiple
# scripts that likely aren't used or tested in continuous integration builds.

function create_log_file {
  if [ ! -f "$LOG" ]; then
    echo "" > "$LOG"
  fi
}

function echo_console_and_log {
  echo "$1"
  echo "$1" >>"$LOG"
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
  git rev-parse --is-inside-git-dir >/dev/null 2>&1 && [ -d .git ]
  return $?
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

function update_plugin {
  (
    cd "$1"
    if is_git_dir; then
      echo_console_and_log "  Updating plugin $1 ..."
      git checkout master >>"$LOG" 2>&1
      git pull --rebase >>"$LOG" 2>&1
    fi
  )
}

function update_plugins {
  # Loop through each plugin dir, and if it's a git repo, update it
  # This needs to be done first so that db:migrate can pull in any plugin-
  # precipitated changes to the database.
  for dir in {gems,vendor}; do
    if [ -d "$dir/plugins" ]; then
      for plugin in $dir/plugins/*; do update_plugin "$plugin"; done
    fi
  done
}

function checkout_master_canvas {
  echo_console_and_log "  Checking out canvas-lms master ..."
  git checkout master >>"$LOG" 2>&1
}

function rebase_canvas {
  echo_console_and_log "  Rebasing canvas-lms on HEAD ..."
  git pull --rebase >>"$LOG" 2>&1
}

function bundle_install {
  echo_console_and_log "  Installing gems (bundle install) ..."
  rm Gemfile.lock* >/dev/null 2>&1
  bundle install >>"$LOG" 2>&1
}

function bundle_install_with_check {
  echo_console_and_log "  Checking your gems (bundle check) ..."
  if bundle check >>"$LOG" 2>&1 ; then
    echo_console_and_log "  Gems are up to date, no need to bundle install ..."
  else
    bundle_install
  fi
}

function rake_db_migrate_dev_and_test {
  echo_console_and_log "  Migrating development DB ..."
  RAILS_ENV=development bundle exec rake db:migrate >>"$LOG" 2>&1

  echo_console_and_log "  Migrating test DB ..."
  RAILS_ENV=test bundle exec rake db:migrate >>"$LOG" 2>&1
}

function install_node_packages {
  echo_console_and_log "  Installing Node packages ..."
  bundle exec rake js:yarn_install >>"$LOG" 2>&1
}

function compile_assets {
  echo_console_and_log "  Compiling assets (css and js only, no docs or styleguide) ..."
  bundle exec rake canvas:compile_assets_dev >>"$LOG" 2>&1
}
