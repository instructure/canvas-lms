#!/bin/bash
set -e
source script/common/utils/common.sh
source script/common/canvas/build_helpers.sh

trap '_canvas_lms_telemetry_report_status' ERR EXIT
SCRIPT_NAME=$0

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME"

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

OS="$(uname)"

# docker-compose version 1.20.0 introduced build-arg that we use for linux
DOCKER_COMPOSE_MIN_VERSION='1.20.0'
DOCKER='y'

if [[ $OS == 'Darwin' ]]; then
  #docker-compose is checked separately
  dependencies='docker docker-machine dinghy'
elif [[ $OS == 'Linux' ]]; then
  #when more dependencies get added, modify Linux install output below
  #docker-compose is checked separately
  dependencies='dory'
else
  echo 'This script only supports MacOS and Linux :('
  exit 1
fi

function setup_docker_environment {
  check_dependencies
  if [[ $OS == 'Darwin' ]]; then
    . script/common/os/mac_setup.sh
  elif [[ $OS == 'Linux' ]]; then
    . script/common/os/linux_setup.sh
  fi
}

setup_docker_environment
message 'Now we can set up Canvas!'
copy_docker_config
setup_docker_compose_override
build_images
check_gemfile
build_assets
create_db
display_next_steps
