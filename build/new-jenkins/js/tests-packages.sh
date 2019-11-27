#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

export COMPOSE_FILE=./docker-compose.new-jenkins-web.yml

docker-compose run --name tests-packages -e COVERAGE web yarn test:packages
