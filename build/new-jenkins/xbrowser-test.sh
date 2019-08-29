#!/bin/bash

docker-compose exec -T web bundle exec rspec -f doc --format html --out results.html --tag xbrowser spec/selenium/
