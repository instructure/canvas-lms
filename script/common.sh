#!/bin/bash

# This file contains commonly used BASH functions for scripting in canvas-lms,
# particularly script/canvas_update and script/rebase_canvas_and_plugins . As such,
# *be careful* when you modify these functions as doing so will impact multiple
# scripts that likely aren't used or tested in continuous integration builds.

if [[ -n "${COMMON_LIB_LOADED-}" ]]; then
     return
fi
COMMON_LIB_LOADED=i_am_here
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"

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
