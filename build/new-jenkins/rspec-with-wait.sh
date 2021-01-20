#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

command=$1
status=0

echo "Running $command"
$command 2>&1 &
command_pid=$!

wait $command_pid || status=$?
echo "Command pid: $command_pid, Command Exit Code: $status"

exit $status
