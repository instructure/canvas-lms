#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# this should only be called if the MASTER_BOUNCER_KEY is available.
if [[ -z "${MASTER_BOUNCER_KEY-}" ]]; then
  echo "MASTER_BOUNCER_KEY not set. cannot run master_bouncer check"
  exit 1
fi

docker run \
  --env MASTER_BOUNCER_KEY=$MASTER_BOUNCER_KEY \
  --env GERRIT_HOST=$GERRIT_HOST \
  --env GERRIT_PROJECT=canvas-lms \
  --env GERGICH_REVIEW_LABEL=Lint-Review \
  --interactive \
  $LINTERS_RUNNER_IMAGE master_bouncer check
