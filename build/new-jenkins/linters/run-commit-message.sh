#!/bin/bash

set -e

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-commit-message --rm web bundle exec ruby script/lint_commit_message
