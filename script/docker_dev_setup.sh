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

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME" "$LOG"

if [[ "$USER" == 'root' ]]; then
  echo 'Please do not run this script as root!'
  echo "I'll ask for your sudo password if I need it."
  exit 1
fi
# remove hidden file if already exists
rm .mutagen &> /dev/null || true

usage () {
  echo "usage:"
  printf "  --mutagen\t\t\t\tUse Mutagen with Docker to setup development environment.\n"
  printf "  -h|--help\t\t\t\tDisplay usage\n\n"
}

die() {
  echo "$*" 1>&2
  usage
  exit 1
}

while :; do
  case $1 in
    -h|-\?|--help)
      usage # Display a usage synopsis.
      exit
      ;;
    --mutagen)
      touch .mutagen
      DOCKER_COMMAND="mutagen compose"
      CANVAS_SKIP_DOCKER_USERMOD='true'
      ;;
    ?*)
      die 'ERROR: Unknown option: ' "$1" >&2
      ;;
    *)
      break
  esac
  shift
done

print_canvas_intro


create_log_file
init_log_file "Docker Dev Setup"
os_setup
message 'Now we can set up Canvas!'
copy_docker_config
setup_docker_compose_override
build_images
docker_compose_up
check_gemfile
build_assets
create_db
display_next_steps
