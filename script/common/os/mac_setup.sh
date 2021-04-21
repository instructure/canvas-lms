#!/bin/bash
source script/common/utils/dinghy_setup.sh

dependencies='docker,docker-machine,docker-compose 1.20.0,dinghy'

message "It looks like you're using a Mac. Let's set that up."
check_dependencies
create_dinghy_vm
start_dinghy_vm
