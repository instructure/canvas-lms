#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-js-$JSPEC_GROUP}

docker-compose --project-name $CONTAINER_NAME run -e CI_NODE_INDEX -e CI_NODE_TOTAL -e FORCE_FAILURE -e RAILS_LOAD_ALL_LOCALES -e TEST_RESULT_OUTPUT_DIR canvas yarn test:karma:headless
