#!/bin/bash

docker-compose build
docker-compose up -d
docker-compose run web bundle exec rails db:create

docker-compose run -T web ./gems/test-all-gems-new-jenkins.sh
