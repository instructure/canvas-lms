#!/bin/bash

docker-compose exec -T web bundle exec rails db:create
