#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

# calculate which group to run
max=$((CI_NODE_TOTAL * DOCKER_PROCESSES))
group=$(((max-CI_NODE_TOTAL * TEST_PROCESS) - CI_NODE_INDEX))
maybeOnlyFailures=()
[ "${1-}" = 'only-failures' ] && maybeOnlyFailures=("--test-options" "'--only-failures'")

# we want actual globbing of individual elements for passing argument literals
# shellcheck disable=SC2068
bundle exec parallel_rspec . \
  --pattern "$TEST_PATTERN" \
  --exclude-pattern "$EXCLUDE_TESTS" \
  -n "$max" \
  --only-group "$group" \
  --verbose \
  --group-by runtime \
  --runtime-log parallel_runtime_rspec.log \
  ${maybeOnlyFailures[@]}
