#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

if [ "${FORCE_FAILURE:-}" == '1' ]; then
  docker-compose --project-name canvas-lms0 exec -T -e FORCE_FAILURE=1 canvas bundle exec flakey_spec_catcher \
      --repeat=$FSC_REPEAT_FACTOR \
      --output=/usr/src/app/tmp/fsc.out \
      --test=spec/force_failure_spec.rb
else
  docker-compose --project-name canvas-lms0 exec -T -e FSC_IGNORE_FILES -e FSC_NODE_TOTAL -e FSC_NODE_INDEX canvas \
      bash -c "cd $DOCKER_WORKDIR && flakey_spec_catcher --repeat=$FSC_REPEAT_FACTOR --output=/usr/src/app/tmp/fsc.out --use-parent"      
fi
