#!/bin/bash

set -e

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-xsslint --rm web \
  node script/xsslint.js
