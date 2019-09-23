#!/bin/bash

if [ $1 ] && [ $1 = 'only-failures' ]; then
  docker-compose exec -T web bundle exec rake 'knapsack:rspec[-O spec/spec.opts --failure-exit-code 99 --only-failures]'
else
  docker-compose exec -T web bundle exec rake 'knapsack:rspec[-O spec/spec.opts --failure-exit-code 99]'
fi
