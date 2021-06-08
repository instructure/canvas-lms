#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

EXIT_CODE=0
PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?

if [[ $PULL_RESULT =~ (TLS handshake timeout|unknown blob|i/o timeout|Internal Server Error|error pulling image configuration|exceeded while awaiting headers|Temporary failure in name resolution) ]]; then
  sleep 10

  EXIT_CODE=0
  PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?
elif [[ $PULL_RESULT =~ (no basic auth credentials) ]]; then
  if [ -z "$STARLORD_USERNAME" ]; then
    echo "unable to automatically recover from an expired or invalid starlord token, wrap the caller in credentials.withStarlordDockerLogin to fix"

    exit $EXIT_CODE
  fi

  docker login --username $STARLORD_USERNAME --password $STARLORD_PASSWORD $BUILD_REGISTRY_FQDN

  EXIT_CODE=0
  PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?
fi

exit $EXIT_CODE
