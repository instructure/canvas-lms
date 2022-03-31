#!/bin/bash
source script/common/utils/common.sh
source script/common/os/linux/impl.sh
source script/common/utils/dory_setup.sh
dependencies='docker,docker-compose 1.20.0,mutagen 0.13.0,mutagen-compose'

message "It looks like you're using Linux. Let's set that up."

print_mutagen_intro
set_service_util
check_dependencies
check_for_dory
start_docker_daemon
setup_docker_as_nonroot
[[ ${skip_dory:-n} == 'y' ]] || start_dory
