#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-packages}
sentry=""
if [[ "${COVERAGE:-}" == "1" ]]; then
  sentry="-e SENTRY_URL -e SENTRY_DSN -e SENTRY_ORG -e SENTRY_PROJECT -e SENTRY_AUTH_TOKEN -e DEPRECATION_SENTRY_DSN"
fi

docker-compose --project-name $CONTAINER_NAME run -e COVERAGE -e FORCE_FAILURE $sentry canvas yarn test:packages
