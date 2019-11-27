#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

export COMPOSE_FILE="docker-compose.new-jenkins-web.yml:docker-compose.new-jenkins-karma.yml"

NAME='tests-karma-'$JSPEC_GROUP

docker-compose run --name $NAME -e COVERAGE karma yarn test:karma:headless
