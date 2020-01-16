#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# this should only be called if the MASTER_BOUNCER_KEY is available.
if [[ -z "${MASTER_BOUNCER_KEY-}" ]]; then
  echo "MASTER_BOUNCER_KEY not set. cannot run master_bouncer check"
  exit 1
fi

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml run \
  -e MASTER_BOUNCER_KEY=$MASTER_BOUNCER_KEY \
  -e GERRIT_HOST=$GERRIT_HOST \
  -e GERRIT_PROJECT=canvas-lms \
  -e GERGICH_REVIEW_LABEL=Lint-Review \
  --name linter-master-bouncer \
  --rm web master_bouncer check
