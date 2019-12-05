#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

NAME='tests-karma-'$JSPEC_GROUP

docker-compose run --name $NAME -e COVERAGE karma yarn test:karma:headless
