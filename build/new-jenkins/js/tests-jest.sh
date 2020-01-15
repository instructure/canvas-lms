#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

CONTAINER_NAME=${CONTAINER_NAME:-tests-jest}
EXTRA=""
if [[ "${COVERAGE:-}" == "1" ]]; then
  EXTRA=":coverage"
fi

docker-compose run --name $CONTAINER_NAME -e COVERAGE -e RAILS_ENV=test web \
    bash -c "bundle exec rails graphql:schema && yarn test:jest$EXTRA --runInBand"
