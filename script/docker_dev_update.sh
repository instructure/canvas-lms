#!/bin/bash

set -e
source script/common/utils/common.sh
source script/common/canvas/build_helpers.sh

LOG="$(pwd)/log/docker_dev_update.log"
DOCKER='true'
SCRIPT_NAME=$0

trap trap_result EXIT
trap "printf '\nTerminated\n' && exit 130" SIGINT

usage () {
  echo "usage:"
  printf "  --update-code [skip-canvas] [skip-plugins [<plugin1>,...]\tRebase canvas-lms and plugins. Optional skip-canvas and\n"
  printf " \t\t\t\t\t\t\t\tskip-plugins. Comma separated list of plugins to skip.\n"
  printf "  -h|--help\t\t\t\t\t\t\tDisplay usage\n\n"
}

die () {
  echo "$*" 1>&2
  usage
  exit 1
}

_canvas_lms_opt_in_telemetry "$SCRIPT_NAME" "$LOG"
if is_mutagen; then
  DOCKER_COMMAND="mutagen compose"
  CANVAS_SKIP_DOCKER_USERMOD='true'
  print_mutagen_intro
fi

while :; do
  case $1 in
    -h|-\?|--help)
      usage
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
    --rebuild)
      REBUILD_DOCKER=true
      ;;
    ?*)
      die 'ERROR: Unknown option: ' "$1" >&2
      ;;
    *)
      break
  esac
  shift
done

# check for docker daemon running before anything else
docker_running || exit 1

if [ -f "docker-compose.override.yml" ]; then
  echo "docker-compose.override.yml exists, skipping copy of default configuration"
else
  echo "Copying default configuration from config/docker-compose.override.yml.example to docker-compose.override.yml"
  cp config/docker-compose.override.yml.example docker-compose.override.yml
fi

if [[ -n "$UPDATE_CODE" ]] || [[ -n "$REBUILD_DOCKER" ]] && [[ "$(docker-compose top | wc -l)" -gt 0 ]]; then
  echo "You should probably stop docker containers before rebasing code"
  prompt "Would you like to attempt to stop containers with docker-compose stop? [y/n]" stop
  if [[ ${stop:-n} == 'y' ]]; then
    docker-compose stop
  else
    echo "Continuing with docker containers running, this may cause errors."
  fi
fi
echo ""

create_log_file
message "Bringing Canvas up to date ..."
init_log_file "Docker Dev Update"
[[ -n "$UPDATE_CODE" ]] && ./script/rebase_canvas_and_plugins.sh "${params[@]}"
if [[ -n "$REBUILD_DOCKER" ]]; then rebuild_docker_images; else check_dockerfile; fi
docker_compose_up
bundle_install_with_check
install_node_packages
compile_assets
rake_db_migrate_dev_and_test
