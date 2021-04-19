#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-jest}
sentry=""
EXTRA=""
if [[ "${COVERAGE:-}" == "1" ]]; then
  EXTRA=":coverage"
  sentry="-e SENTRY_URL -e SENTRY_DSN -e SENTRY_ORG -e SENTRY_PROJECT -e SENTRY_AUTH_TOKEN -e DEPRECATION_SENTRY_DSN"
fi

docker-compose --project-name $CONTAINER_NAME run -e COVERAGE -e FORCE_FAILURE -e RAILS_ENV=test $sentry canvas \
    bash -c "bundle exec rails graphql:schema && yarn test:jest$EXTRA"
