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
  printf "  --update-code [skip-canvas] [skip-plugins [<plugin1>,...]\tRebase canvas-lms and plugins. Optional skip-canvas and\n"
  printf " \t\t\t\t\t\t\t\tskip-plugins. Comma separated list of plugins to skip.\n"
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
    --update-code)
      UPDATE_CODE=true
      before_rebase_sha="$(git rev-parse HEAD)"
      params=()
      while :; do
        case $2 in
          skip-canvas)
            unset before_rebase_sha
            params+=(--skip-canvas)
            ;;
          skip-plugins)
            if [ "$3" ] && [[ "$3" != "skip-canvas" ]]; then
              repos=$3
              params+=(--skip-plugins $repos)
              shift
            else
              params+=(--skip-plugins)
            fi
            ;;
          *)
            break
        esac
        shift
      done
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
docker_running || exit 1
containers_running
[[ -n "$UPDATE_CODE" ]] && ./script/rebase_canvas_and_plugins.sh "${params[@]}"
copy_docker_config
setup_docker_compose_override
check_gemfile
build_images
docker_compose_up
create_db
display_next_steps
