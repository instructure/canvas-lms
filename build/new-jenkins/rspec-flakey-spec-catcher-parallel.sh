#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

PROCESSES=$((${RSPEC_PROCESSES:=1}-1))

cd /usr/src/app
command_pids=()

for i in $(seq 0 $PROCESSES); do
  PARALLEL_INDEX=$i RAILS_DB_NAME_TEST="canvas_test_$i" bin/flakey_spec_catcher . \
  --repeat="$FSC_REPEAT_FACTOR" \
  --output=/usr/src/app/tmp/fsc.out \
  --test="$FSC_TESTS" \
  --use-parent 2>&1 &
  command_pids+=("$!")
done

for command_pid in "${command_pids[@]}"; do
  wait $command_pid
done
