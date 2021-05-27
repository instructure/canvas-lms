#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-jest}

docker-compose --project-name $CONTAINER_NAME run -e FORCE_FAILURE -e RAILS_ENV=test -e TEST_RESULT_OUTPUT_DIR canvas \
    bash -c "bundle exec rails graphql:schema && yarn test:jest"
