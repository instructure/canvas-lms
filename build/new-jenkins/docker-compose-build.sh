#!/bin/bash

export COMPOSE_FILE=docker-compose.new-jenkins.yml

docker-compose build
docker-compose up -d
docker-compose run web bundle exec rails db:create db:migrate
