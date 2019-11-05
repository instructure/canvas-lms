#!/bin/bash

set -ex

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-brakeman --rm web bundle exec ruby script/brakeman
