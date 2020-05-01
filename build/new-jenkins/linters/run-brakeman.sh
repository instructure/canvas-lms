#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose --file $WORKSPACE/docker-compose.new-jenkins.canvas.yml \
  run --name linter-brakeman --rm canvas bundle exec ruby script/brakeman
