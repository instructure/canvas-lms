#!/bin/bash
source script/common/utils/common.sh
source script/common/utils/dinghy_setup.sh
source script/common/utils/dory_setup.sh
source script/common/utils/docker_desktop_setup.sh

function dory_or_dinghy() {
  if $(installed dory) && $(! [[ "$(docker ps -aq --filter ancestor=codekitchen/dinghy-http-proxy)" == "" ]]); then
    message 'Found both dory and dinghy_http_proxy!'
    prompt "Use Dory or dinghy_http_proxy? [dory/dinghy]" option
    shopt -s nocasematch;if [[ "${option:-}" == 'dory' ]]; then
      message "Stopping and removing dinghy_http_proxy container."
      docker rm -fv $(docker ps -aq --filter ancestor=codekitchen/dinghy-http-proxy)
      start_dory
    elif [[ "${option:-}" == 'dinghy' ]]; then
      setup_dinghy_proxy
    else
      message "\"${option:-}\" is not a valid option!"
      exit 1
    fi
  elif $(installed dory); then
    start_dory
  else
    setup_dinghy_proxy
  fi
}

message "It looks like you're using a Mac. Let's set that up."

if is_mutagen; then
  print_mutagen_intro
  dependencies='docker,mutagen 0.13.0,mutagen-compose'
  check_dependencies
  check_for_docker_desktop
  docker_running &> /dev/null || attempt_start_docker
  check_docker_memory
  dory_or_dinghy
else
  dependencies='docker,docker-machine,docker-compose 1.20.0,dinghy'
  check_dependencies
  create_dinghy_vm
  start_dinghy_vm
fi
