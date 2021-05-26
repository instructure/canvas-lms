#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CONTAINER_NAME=${CONTAINER_NAME:-tests-packages}

docker-compose --project-name $CONTAINER_NAME run -e FORCE_FAILURE canvas yarn test:packages
