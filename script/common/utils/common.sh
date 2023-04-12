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
DOCKER_COMMAND=${DOCKER_COMMAND:-"docker-compose"}

function trap_result {
  exit_code=$?
  last_command=$BASH_COMMAND
  exec &>/dev/tty
  set +e
  stop_spinner $exit_code
  if [ "${exit_code}" == "0" ]; then
    echo ""
    echo_console_and_log "  \o/ Success!"
    _canvas_lms_telemetry_report_status $exit_code
  elif [ "${exit_code}" == "130" ]; then
    echo_console_and_log "  /o\ Script interrupted. Check ${LOG} for details."
    _canvas_lms_telemetry_report_status $exit_code
  else
    echo ""
    echo_console_and_log "  /o\ Something went wrong. Check ${LOG} for details."
    _canvas_lms_telemetry_report_status $exit_code "$last_command" "$ERROR_LOG_FILE"
  fi
  trap - EXIT
  exit ${exit_code}
}

function is_git_dir {
  [ "$(basename "$(git rev-parse --show-toplevel)")" == "$(basename "$(pwd)")" ]
}


# If DOCKER var set true, run with docker-compose
function run_command {
  if is_running_on_jenkins; then
    docker-compose exec -T web "$@"
  elif is_docker; then
    # -T needed until https://github.com/docker/compose/issues/9104 is fixed
    $DOCKER_COMMAND exec -T -e TELEMETRY_OPT_IN web "$@"
  else
    "$@"
  fi
}
# remove once https://github.com/docker/compose/issues/9104 is fixed
function run_command_tty {
  if is_running_on_jenkins; then
    docker-compose exec -T web "$@"
  elif is_docker; then
    # -T needed until https://github.com/docker/compose/issues/9104 is fixed
    $DOCKER_COMMAND exec -e TELEMETRY_OPT_IN web "$@"
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
  if [ -n "$CANVAS_LMS_ACTIVATE_TELEMETRY" ]; then
    eval "$CANVAS_LMS_ACTIVATE_TELEMETRY"
  fi
  SCRIPT_NAME=$1
  LOG_FILE=$2
  export ERROR_LOG_FILE=$LOG_FILE.error
  if installed _canvas_lms_activate_telemetry; then
    _canvas_lms_activate_telemetry
    if installed _inst_setup_telemetry && _inst_setup_telemetry "canvas-lms:$SCRIPT_NAME"; then
      _inst_track_os
      if [[ ! -z "${LOG_FILE-}" ]]; then
        _inst_set_redirect_log_file "$LOG_FILE"
        > $ERROR_LOG_FILE
        # duplicate stderr on a log file for untracked commands
        exec 2>  >(tee  $ERROR_LOG_FILE)
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
    failed_command=${2-}
    error_file=${3-}
    if [ -s "$error_file" ]; then
      _inst_untracked_failure $exit_status "$failed_command" "$error_file"
    fi
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
  start_spinner "Starting docker containers..."
  _canvas_lms_track_with_log $DOCKER_COMMAND up -d web
  stop_spinner
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
      version=$(eval "${dep[0]}" version | grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+" | head -1)
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

function check_dockerfile {
  if [ -n "$(git diff --name-only "${before_rebase_sha:-origin/master}" | grep -E 'Dockerfile$|Dockerfile.githook$|docker-compose/postgres/Dockerfile$')" ]; then
    message "There have been some updates made to Dockerfile, you should rebuild your docker images."
    prompt "Rebuild docker images? [y/n]" rebuild_image
    if [ "${rebuild_image:n}" == 'y' ]; then
      rebuild_docker_images
    else
      echo "Your docker image is now outdated and needs to be rebuilt! You should run \"${DOCKER_COMMAND} build\"."
    fi
  fi
}

function rebuild_docker_images {
  start_spinner "Rebuilding docker images..."
    if [[ "${OS:-}" == 'Linux' && -z "${CANVAS_SKIP_DOCKER_USERMOD:-}" ]]; then
      _canvas_lms_track_with_log docker-compose build --pull --build-arg USER_ID=$(id -u)
    else
      _canvas_lms_track_with_log $DOCKER_COMMAND build --pull
    fi
  stop_spinner
}

function is_docker {
  [[ "${DOCKER:-}" == 'true' ]]
}

function docker_running {
  if ! docker info &> /dev/null; then
  echo "Docker is not running! Start docker daemon and try again."
  return 1
fi
}

function os_setup {
  if [[ $OS == 'Darwin' ]]; then
    . script/common/os/mac/dev_setup.sh
  elif [[ $OS == 'Linux' ]]; then
    . script/common/os/linux/dev_setup.sh
  else
    echo 'This script only supports MacOS and Linux :('
    exit 1
  fi
}

function detect_local_canvas {
  if [ -f "log/development.log" ] && [ -f "config/database.yml" ]; then
    echo "
It looks like you've run Canvas outside of Docker from this workspace.
If you continue with this script, your local Canvas configuration will be
overwritten and this workspace will be usable only inside Docker.
If that's not what you want, please check out a separate copy of Canvas
to use inside Docker.
"
    prompt "Continue setting up Dockerized Canvas here? [y/n]" confirm
    if [[ ${confirm:-n} != 'y' ]]; then
      exit 1
    fi
  fi
}

function print_canvas_intro {
  # shellcheck disable=1004
  echo '
  ________  ________  ________   ___      ___ ________  ________
|\   ____\|\   __  \|\   ___  \|\  \    /  /|\   __  \|\   ____\
\ \  \___|\ \  \|\  \ \  \\ \  \ \  \  /  / | \  \|\  \ \  \___|_
 \ \  \    \ \   __  \ \  \\ \  \ \  \/  / / \ \   __  \ \_____  \
  \ \  \____\ \  \ \  \ \  \\ \  \ \    / /   \ \  \ \  \|____|\  \
   \ \_______\ \__\ \__\ \__\\ \__\ \__/ /     \ \__\ \__\____\_\  \
    \|_______|\|__|\|__|\|__| \|__|\|__|/       \|__|\|__|\_________\
                                                         \|_________|

Welcome! This script will guide you through the process of setting up a
Canvas development environment.'
}
