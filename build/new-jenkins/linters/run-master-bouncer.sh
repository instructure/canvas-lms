#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

if [[ -z "${MASTER_BOUNCER_KEY}" ]]; then
  echo "MASTER_BOUNCER_KEY not set. cannot run master_bouncer check"
  exit 0
fi

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-master-bouncer --rm web bundle exec master_bouncer
