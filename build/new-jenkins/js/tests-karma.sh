#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-karma-$JSPEC_GROUP}
sentry=""
if [[ "${COVERAGE:-}" == "1" ]]; then
  sentry="-e SENTRY_URL -e SENTRY_DSN -e SENTRY_ORG -e SENTRY_PROJECT -e SENTRY_AUTH_TOKEN -e DEPRECATION_SENTRY_DSN"
fi

docker-compose run --name $CONTAINER_NAME -e CI_NODE_INDEX -e CI_NODE_TOTAL -e COVERAGE -e FORCE_FAILURE $sentry karma yarn test:karma:headless
