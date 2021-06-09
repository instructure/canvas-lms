#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-packages}

# TEST_RESULT_OUTPUT_DIR needs to be an absolute path because each package otherwise runs from its own directory.
docker-compose --project-name $CONTAINER_NAME run -e FORCE_FAILURE -e TEST_RESULT_OUTPUT_DIR=/usr/src/app/$TEST_RESULT_OUTPUT_DIR canvas yarn test:packages
