#!/bin/bash

export COMPOSE_FILE=docker-compose.new-jenkins.yml

docker-compose run --rm web bundle exec rspec -f doc --format html --out results.html --tag xbrowser spec/selenium/
