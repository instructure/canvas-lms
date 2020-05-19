#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose --file $(pwd)/docker-compose.new-jenkins.canvas.yml \
  run --name linter-stylelint --rm canvas bundle exec ruby script/stylelint
