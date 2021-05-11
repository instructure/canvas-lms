#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose --project-name "canvas-lms0" exec -T -e RSPEC_PROCESSES=$RSPEC_PROCESSES -e FORCE_FAILURE=$FORCE_FAILURE -e FSC_REPEAT_FACTOR=$FSC_REPEAT_FACTOR -e FSC_TESTS=$FSC_TESTS canvas bash -c 'build/new-jenkins/rspec-flakey-spec-catcher-parallel.sh'
