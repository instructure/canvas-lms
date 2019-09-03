#!/bin/bash

export COMPOSE_FILE=./docker-compose.new-jenkins-web.yml

docker-compose run --name linter-eslint web bundle exec ruby script/eslint
