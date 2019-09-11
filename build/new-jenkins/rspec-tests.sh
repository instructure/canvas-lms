#!/bin/bash

if [ $1 ] && [ $1 = 'only-failures' ]; then
  docker-compose exec -T web bundle exec rspec -O spec/spec.opts --only-failures
else
  docker-compose exec -T web bundle exec rake 'knapsack:rspec[-O spec/spec.opts]'
fi
