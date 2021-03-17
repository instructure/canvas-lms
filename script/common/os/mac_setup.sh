#!/bin/bash
source script/common/utils/dinghy_setup.sh

# TODO use in dependency refactor; dependencies='docker,docker-machine,docker-compose 1.20.0,dinghy'

message "It looks like you're using a Mac. You'll need a dinghy VM. Let's set that up."
create_dinghy_vm
start_dinghy_vm
