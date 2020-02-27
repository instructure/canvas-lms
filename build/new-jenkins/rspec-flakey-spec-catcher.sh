#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose exec -T -e FSC_NODE_TOTAL -e FSC_NODE_INDEX web \
    bundle exec flakey_spec_catcher \
    --repeat=$FSC_REPEAT_FACTOR \
    --output=/usr/src/app/tmp/fsc.out \
    --use-parent
