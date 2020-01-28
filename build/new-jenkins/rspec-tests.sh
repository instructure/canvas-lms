#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

if [ "${1-}" = 'only-failures' ]; then
  docker-compose exec -T -e ERROR_CONTEXT_BASE_PATH=$ERROR_CONTEXT_BASE_PATH web bundle exec rake 'knapsack:rspec[--options spec/spec.opts --failure-exit-code 99 --only-failures]'
else
  docker-compose exec -T -e ERROR_CONTEXT_BASE_PATH=$ERROR_CONTEXT_BASE_PATH web bundle exec rake 'knapsack:rspec[--options spec/spec.opts --failure-exit-code 99]'
fi
