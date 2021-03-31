#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

# required script parameters
parallel_index=$1
only_failures=${2-}

# calculate which group to run
max=$((CI_NODE_TOTAL * (DOCKER_PROCESSES * RSPEC_PROCESSES)))
group=$(((max-CI_NODE_TOTAL * $parallel_index) - CI_NODE_INDEX))
maybeOnlyFailures=()
if [ "${only_failures}" = 'only-failures' ] && [ ! "${RSPEC_LOG:-}" == "1" ]; then
  maybeOnlyFailures=("--test-options" "'--only-failures'")
fi

# we want actual globbing of individual elements for passing argument literals
# shellcheck disable=SC2068
PARALLEL_INDEX=$parallel_index RAILS_DB_NAME_TEST="canvas_test_$parallel_index" bin/parallel_rspec . \
  --pattern "$TEST_PATTERN" \
  --exclude-pattern "$EXCLUDE_TESTS" \
  -n "$max" \
  --only-group "$group" \
  --verbose \
  --group-by runtime \
  --runtime-log log/parallel-runtime-rspec.log \
  ${maybeOnlyFailures[@]}
