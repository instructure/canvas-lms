#!/bin/bash

export COMPOSE_FILE=./docker-compose.new-jenkins-js.yml

docker-compose run --name tests-packages web yarn test:packages
