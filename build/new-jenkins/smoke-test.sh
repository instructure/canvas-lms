#!/bin/bash

# -O spec/spec.opts runs rspec with our formatters for failure reports
docker-compose exec -T web bundle exec rspec -O spec/spec.opts spec/selenium/login_logout_spec.rb
