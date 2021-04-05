#!/bin/bash
source script/common/utils/common.sh
source script/common/utils/dinghy_setup.sh
source script/common/utils/docker_desktop_setup.sh

message "It looks like you're using a Mac. Let's set that up."

if is_mutagen; then
  print_mutagen_intro
  dependencies='docker,mutagen'
  check_dependencies
  check_for_docker_desktop
  docker_running &> /dev/null || attempt_start_docker
  check_docker_memory
  setup_dinghy_proxy
else
  dependencies='docker,docker-machine,docker-compose 1.20.0,dinghy'
  check_dependencies
  create_dinghy_vm
  start_dinghy_vm
fi
