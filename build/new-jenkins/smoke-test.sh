#!/bin/bash

export COMPOSE_FILE=docker-compose.new-jenkins.yml

# cleanup docker environment
function cleanup() {
  exit_val=$?
  docker-compose down --volumes --rmi local
  exit $exit_val
}
trap cleanup INT TERM EXIT

docker-compose build

docker-compose run --rm web bundle exec rails db:create db:migrate
docker-compose run --rm web bundle exec rspec spec/selenium/login_logout_spec.rb
