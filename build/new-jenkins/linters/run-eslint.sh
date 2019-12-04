#!/bin/bash

set -e

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-eslint --rm web bundle exec ruby script/eslint
