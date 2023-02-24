#!/bin/bash
set -e
source script/common/utils/common.sh
source script/common/canvas/build_helpers.sh

trap 'trap_result' ERR EXIT
trap "printf '\nTerminated\n' && exit 130" SIGINT

LOG="$(pwd)/log/docker_dev_setup.log"
SCRIPT_NAME="$0 $@"
OS="$(uname)"
DOCKER='true'
CANVAS_SKIP_DOCKER_USERMOD='true'

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME" "$LOG"

if [[ "$USER" == 'root' ]]; then
  echo 'Please do not run this script as root!'
  echo "I'll ask for your sudo password if I need it."
  exit 1
fi

print_canvas_intro

if [[ $OS == 'Darwin' ]]; then
  source script/common/utils/dinghy_proxy_setup.sh
  dinghy_machine_exists && exit 1
fi

create_log_file
init_log_file "Docker Dev Setup"
detect_local_canvas
os_setup
message 'Now we can set up Canvas!'
copy_docker_config
setup_docker_compose_override
build_images
docker_compose_up
build_assets
create_db
display_next_steps
