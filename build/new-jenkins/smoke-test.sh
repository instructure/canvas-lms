#!/bin/bash

docker-compose exec -T web bundle exec rspec spec/selenium/login_logout_spec.rb -f doc --format html --out results.html
