#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose --project-name "canvas-lms$1" exec -T -e FORCE_FAILURE=$FORCE_FAILURE canvas \
    bash -c "cd /usr/src/app && bundle exec flakey_spec_catcher \
    --repeat=$FSC_REPEAT_FACTOR \
    --output=/usr/src/app/tmp/fsc.out \
    --test=$FSC_TESTS \
    --use-parent"
