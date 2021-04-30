#!/bin/bash
set -e
source script/common/utils/common.sh
source script/common/canvas/build_helpers.sh
SCRIPT_NAME="$0"
warning_message "$SCRIPT_NAME is deprecated and will removed in the near future. Please use script/docker_dev_setup.sh
for updating your docker environment."
