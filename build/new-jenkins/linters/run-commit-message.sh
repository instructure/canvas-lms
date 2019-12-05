#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-commit-message --rm web bundle exec ruby script/lint_commit_message
