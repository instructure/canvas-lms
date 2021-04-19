#!/bin/bash
source script/common/utils/spinner.sh
source script/common/utils/logging.sh

# This file contains commonly used BASH functions for scripting in canvas-lms,
# particularly script/canvas_update and script/rebase_canvas_and_plugins . As such,
# *be careful* when you modify these functions as doing so will impact multiple
# scripts that likely aren't used or tested in continuous integration builds.

if [[ -n "${COMMON_LIB_LOADED-}" ]]; then
     return
fi
COMMON_LIB_LOADED=i_am_here

function trap_result {
  exit_code=$?
  set +e
  stop_spinner $exit_code
  if [ "${exit_code}" == "0" ]; then
    echo ""
    echo_console_and_log "  \o/ Success!"
    _canvas_lms_telemetry_report_status $exit_code
  else
    echo ""
    echo_console_and_log "  /o\ Something went wrong. Check ${LOG} for details."
    _canvas_lms_telemetry_report_status $exit_code
  fi
  exit ${exit_code}
}

function is_git_dir {
  [ "$(basename "$(git rev-parse --show-toplevel)")" == "$(basename "$(pwd)")" ]
}


# If DOCKER var set true, run with docker-compose
function run_command {
  if is_running_on_jenkins; then
    docker-compose exec -T web "$@"
  elif [ "${DOCKER:-}" == 'y' ]; then
    docker-compose exec -e TELEMETRY_OPT_IN web "$@"
  else
    "$@"
  fi
}

function _canvas_lms_track {
  command="$@"
  if _canvas_lms_telemetry_enabled; then
    _inst_telemetry $command
  else
    $command
  fi
}

function _canvas_lms_track_with_log {
  command="$@"
  if _canvas_lms_telemetry_enabled; then
    _inst_telemetry_with_log $command
  elif ! is_running_on_jenkins; then
    $command >> "$LOG" 2>&1
  else
    $command
  fi
}

function _canvas_lms_telemetry_enabled() {
  if [[ "${TELEMETRY_OPT_IN-n}" == 'y' ]] && installed _inst_telemetry ; then
    return 0
  fi
  return 1
}

function _canvas_lms_opt_in_telemetry() {
  SCRIPT_NAME=$1
  LOG_FILE=$2
  if installed _canvas_lms_activate_telemetry; then
    _canvas_lms_activate_telemetry
    if installed _inst_setup_telemetry && _inst_setup_telemetry "canvas-lms:$SCRIPT_NAME"; then
      _inst_track_os
      if [[ ! -z "${LOG_FILE-}" ]]; then
        _inst_set_redirect_log_file "$LOG_FILE"
      fi
    fi
  fi
}

function installed {
  type "$@" &> /dev/null
}

function _canvas_lms_telemetry_report_status() {
  exit_status=$?
  if [[ ! -z ${1-} ]]; then
    exit_status=$1
  fi
  stop_spinner $exit_status
  if installed _inst_report_status && _canvas_lms_telemetry_enabled; then
    _inst_report_status $exit_status
  fi
}

function confirm_command {
  if ! is_running_on_jenkins; then
    prompt "OK to run '$*'? [y/n]" confirm
    [[ ${confirm:-n} == 'y' ]] || return 1
  fi
  eval "$*"
}

function docker_compose_up {
  message "Starting docker containers..."
  _canvas_lms_track_with_log docker-compose up -d web
}

function check_dependencies {
  message "Checking Dependencies..."
  missing_packages=()
  wrong_version=()
  IFS=',' read -r -a DEPS <<< "$dependencies"
  for dependency in "${DEPS[@]}"; do
    IFS=' ' read -r -a dep <<< "$dependency"
    if ! installed "${dep[0]}"; then
      missing_packages+=("$dependency")
      continue
    fi
    if [[ ${#dep[@]} -gt 1 ]]; then
      version=$(eval "${dep[0]}" --version |grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")
      if (( $(echo "$version ${dep[1]}" | awk '{print ($1 < $2)}') )); then
        wrong_version+=("$dependency or higher. Found: ${dep[0]} $version.")
      fi
    fi
  done
  if [[ ${#missing_packages[@]} -gt 0 ]] || [[ ${#wrong_version[@]} -gt 0 ]]; then
    message "Some additional dependencies need to be installed before continuing."
    print_missing_dependencies
  fi
}

function is_running_on_jenkins() {
  [[ -n "${JENKINS:-}" ]]
}
