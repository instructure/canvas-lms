#!/bin/bash

# -O spec/spec.opts runs rspec with our formatters for failure reports
docker-compose exec -T web bundle exec rspec -O spec/spec.opts --tag xbrowser spec/selenium/
