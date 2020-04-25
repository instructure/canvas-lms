#!/bin/bash

set -o errexit -o errtrace -o pipefail -o xtrace

# calculate which group to run
max=$((CI_NODE_TOTAL*DOCKER_PROCESSES))
group=$(((max-CI_NODE_TOTAL*TEST_PROCESS)-CI_NODE_INDEX))

if [ "${1-}" = 'only-failures' ]; then
  bundle exec parallel_rspec ./ --pattern $TEST_PATTERN --exclude-pattern $EXCLUDE_TESTS -n $max --only-group $group --verbose --group-by runtime --runtime-log parallel_runtime_rspec.log  --test-options '--only-failures'
else
  bundle exec parallel_rspec ./ --pattern $TEST_PATTERN --exclude-pattern $EXCLUDE_TESTS -n $max --only-group $group --verbose --group-by runtime --runtime-log parallel_runtime_rspec.log
fi
