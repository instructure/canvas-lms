#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

EXIT_CODE=0
PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?

if echo $PULL_RESULT | grep -q "net/http: TLS handshake timeout"; then
  sleep 10

  PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?
elif echo $PULL_RESULT | grep -q "unknown blob"; then
  sleep 10

  PULL_RESULT=$(docker $1 $2 2>&1) || EXIT_CODE=$?
fi

exit $EXIT_CODE
