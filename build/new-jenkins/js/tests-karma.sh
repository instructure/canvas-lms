#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

CONTAINER_NAME=${CONTAINER_NAME:-tests-karma-$JSPEC_GROUP}

docker-compose run --name $CONTAINER_NAME -e COVERAGE karma yarn test:karma:headless
