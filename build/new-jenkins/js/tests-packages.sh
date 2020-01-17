#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

CONTAINER_NAME=${CONTAINER_NAME:-tests-packages}
sentry=""
if [[ "${COVERAGE:-}" == "1" ]]; then
  sentry="-e SENTRY_URL -e SENTRY_DSN -e SENTRY_ORG -e SENTRY_PROJECT -e SENTRY_AUTH_TOKEN -e DEPRECATION_SENTRY_DSN"
fi

docker-compose run --name $CONTAINER_NAME -e COVERAGE -e FORCE_FAILURE $sentry web yarn test:packages
