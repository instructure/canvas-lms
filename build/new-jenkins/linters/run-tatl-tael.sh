#!/bin/bash

set -e

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-tatl-tael --rm web bundle exec ruby script/tatl_tael
