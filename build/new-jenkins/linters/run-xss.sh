#!/bin/bash

set -e

docker-compose --file $WORKSPACE/docker-compose.new-jenkins-web.yml \
  run --name linter-xsslint --rm web \
  bundle exec gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
