#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

if [ "${IS_PLUGIN}" == "1" ]; then
   docker-compose --project-name "canvas-lms$1" exec -T -e FORCE_FAILURE=$FORCE_FAILURE canvas \
         bash -c "cd $DOCKER_WORKDIR && BUNDLE_GEMFILE=../../../Gemfile bundle exec flakey_spec_catcher \
         --repeat=$FSC_REPEAT_FACTOR \
         --output=/usr/src/app/tmp/fsc.out \
         --use-parent \
         --test=$FSC_TESTS \
         --rspec-options '-I spec_canvas'"
else
  docker-compose --project-name "canvas-lms$1" exec -T -e FORCE_FAILURE=$FORCE_FAILURE canvas \
      bash -c "cd $DOCKER_WORKDIR && bundle exec flakey_spec_catcher \
      --repeat=$FSC_REPEAT_FACTOR \
      --output=/usr/src/app/tmp/fsc.out \
      --test=$FSC_TESTS \
      --use-parent"
fi
