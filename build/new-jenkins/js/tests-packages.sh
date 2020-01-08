#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

CONTAINER_NAME=${CONTAINER_NAME:-tests-packages}

docker-compose run --name $CONTAINER_NAME -e COVERAGE web yarn test:packages
