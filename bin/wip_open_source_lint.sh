#!/usr/bin/env bash

# open_source_lint.sh is designed to run the linters in the same way as Jenkins.
# rspect/hudson_setup_functions.sh has been modified to run standalone.
#
# Use case is running the linters locally. Exit code isn't propagated correctly for CI.
#
# Comment/uncomment the desired linter tasks in 'function build_tasklist'
#
# To run, install the Ruby and nodejs dependencies:
# bundle install
# yarn
#
# As of March 12, 2018. Recommended versions: node 8.10.0, Yarn 1.5.1

function red {
  echo -e "\033[31m$1\033[0m"
}

function green {
  echo -e "\033[32m$1\033[0m"
}

function i18n_check {
  bundle exec gergich capture i18nliner "rake i18n:check"
}

function test_migrations {
  unset PUSH_DOCKER_VOLUME_ARCHIVE
  unset PUBLISH_DOCKER_ARTIFACTS

  run_task run_snapshot_migrations &
  snapshot_pid=$!

  run_task run_full_migrations &
  full_pid=$!

  wait $snapshot_pid || { echo "ERROR: Snapshotted migrations failed!"; return 1; }
  wait $full_pid     || { echo "ERROR: Full migrations failed!"; return 1; }

  diff -U 10 /tmp/canvas_structure.sql /tmp/canvasfull_structure.sql || {
    echo "ERROR: snapshotted and full migrations resulted in a different schema!";
    return 1;
  }
}

function eslint {
  bundle exec ruby script/eslint
}

function lint_commit_message {
  bundle exec script/lint_commit_message
}

function rebase_checker {
  master_bouncer check
}

function rlint {
  bundle exec ruby script/rlint
}

function stylelint {
  bundle exec ruby script/stylelint
}

function tatl_tael {
  bundle exec ruby script/tatl_tael
}

function xsslint {
  gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint \
    "node script/xsslint.js"
}

function run_brakeman {
  bundle exec ruby script/brakeman
}

function graphQL_schema_check {
  bundle exec rails graphql:schema
  # if the generated file is different from the checked in file, fail
  if ! git diff --exit-code schema.graphql; then
    echo "Error: GraphQL Schema changes are not checked in"
    echo "run 'bundle exec rails graphql:schema' to generate graphql.schema file"
    return 1
  else
    echo "GraphQL schema changes passed"
  fi
}

function build_tasklist {
  echo "Building tasklist..."

  build_spec_tasklist=() # if there are multiple, they will run in parallel

  # if [[ "$BUILD_LINT" == "1" ]]; then
    # build_spec_tasklist+=("i18n_check") # works. requires yarn deps
    # build_spec_tasklist+=("test_migrations") # errors. missing functions.
    build_spec_tasklist+=("eslint") # works
    build_spec_tasklist+=("lint_commit_message") # works
    # build_spec_tasklist+=("rebase_checker") # requires MASTER_BOUNCER_KEY
    build_spec_tasklist+=("rlint") # works
    build_spec_tasklist+=("stylelint") # works
    build_spec_tasklist+=("tatl_tael") # works
    # build_spec_tasklist+=("xsslint") # works. lots of XSS errors on master.
    # build_spec_tasklist+=("run_brakeman") # works. kind of slow.
    # build_spec_tasklist+=("graphQL_schema_check") # requires config/database.yml
}

function run_all_tasks {
  build_tasklist

  echo "Starting tasks..."
  run_parallel_tasks "${build_spec_tasklist[@]}" || :
}

function run_parallel_tasks {
  tasks=("$@")

  # these will run in parallel
  task_pids=()
  for task in "${tasks[@]}"; do
    run_task $task &
    task_pids+=($!)
  done
  for i in "${!task_pids[@]}"; do
    task_pid=${task_pids[$i]}
    last_status=0
    wait $task_pid || last_status=$?
    [[ $last_status != 0 ]] && failed_tasks+=("${tasks[$i]}")
    let "exit_status=exit_status?exit_status:$last_status" || :
  done
  return $exit_status
}

function run_task {
  exit_on_failure=0 log_and_run_command "$@"
}

# ah the hoops we have to jump through to prefix stdout, w/o necessarily
# running our command in a subshell (if a bash function) :P
function log_and_run_command {
  command="$@"

  last_status=0
  echo "$command"
  eval '$command; last_status=$?'

  if [[ $last_status != 0 ]]; then
    echo `red "$command: FAILED! (exit code $last_status)"`
  else
    echo `green "$command: OK"`
  fi
  echo "$command: FINISHED"

  return $last_status
}

run_all_tasks

# # Sample Travis CI config
#
# language: ruby
# sudo: false
# cache:
#   bundler: true
#   yarn: true
#   directories:
#     - vendor/bundle
#     - node_modules
#
# rvm:
#   - 2.4.3
#
# notifications:
#   email: false
#
# before_install:
# - sudo apt-get update -qq
# - sudo apt-get install -qq libxmlsec1-dev
#
# script: './open_source_lint.sh'
