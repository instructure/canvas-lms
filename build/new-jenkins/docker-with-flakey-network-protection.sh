#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

run_docker() {
  TMPFILE=$(mktemp)
  EXIT_CODE=0
  docker "$@" 2>&1 | tee "$TMPFILE" || EXIT_CODE=$?
  PULL_RESULT=$(cat "$TMPFILE")
  rm -f "$TMPFILE"
}

run_docker "$@"

if [[ $PULL_RESULT =~ (TLS handshake timeout|unknown blob|i/o timeout|Internal Server Error|error pulling image configuration|exceeded while awaiting headers|Temporary failure in name resolution) ]]; then
  sleep 10
  EXIT_CODE=0
  run_docker "$@"
elif [[ $PULL_RESULT =~ (no basic auth credentials) ]]; then
  if [ -z "${STARLORD_USERNAME:-}" ]; then
    echo "no basic auth credentials for starlord; skipping retry"
    exit $EXIT_CODE
  fi

  docker login \
    --username "$STARLORD_USERNAME" \
    --password "$STARLORD_PASSWORD" \
    starlord.inscloudgate.net

  EXIT_CODE=0
  run_docker "$@"
fi

exit $EXIT_CODE
