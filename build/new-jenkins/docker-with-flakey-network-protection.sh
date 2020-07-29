#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

EXIT_CODE=0
PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?

if [[ $PULL_RESULT =~ (TLS handshake timeout|unknown blob|i/o timeout|Internal Server Error) ]]; then
  sleep 10

  EXIT_CODE=0
  PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?
fi

exit $EXIT_CODE
