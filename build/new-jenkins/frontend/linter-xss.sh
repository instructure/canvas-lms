#!/bin/bash

export COMPOSE_FILE=./docker-compose.new-jenkins-web.yml

docker-compose run --name linter-xsslint web bundle exec gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
