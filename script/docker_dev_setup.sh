#!/bin/bash
set -e
source script/common/utils/common.sh
source script/common/canvas/build_helpers.sh

trap 'trap_result' ERR EXIT
trap "printf '\nTerminated\n' && exit 130" SIGINT
LOG="$(pwd)/log/docker_dev_setup.log"
SCRIPT_NAME=$0
OS="$(uname)"
DOCKER='y'

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME" "$LOG"

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
Canvas development environment with docker and dinghy/dory.

When you git pull new changes, you can run ./scripts/docker_dev_update.sh
to bring everything up to date.'

if [[ "$USER" == 'root' ]]; then
  echo 'Please do not run this script as root!'
  echo "I'll ask for your sudo password if I need it."
  exit 1
fi

function setup_docker_environment {
  if [[ $OS == 'Darwin' ]]; then
    . script/common/os/mac_setup.sh
  elif [[ $OS == 'Linux' ]]; then
    . script/common/os/linux_setup.sh
  else
    echo 'This script only supports MacOS and Linux :('
    exit 1
  fi
}

create_log_file
init_log_file "Docker Dev Setup"
setup_docker_environment
message 'Now we can set up Canvas!'
copy_docker_config
setup_docker_compose_override
build_images
check_gemfile
docker_compose_up
build_assets
create_db
display_next_steps
