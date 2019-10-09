#!/bin/bash

export COMPOSE_FILE=./docker-compose.new-jenkins-web.yml

docker-compose run --name tests-jest -e COVERAGE web yarn test:jest --runInBand
