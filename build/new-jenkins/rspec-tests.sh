#!/bin/bash

docker-compose exec -T web bundle exec rake 'knapsack:rspec[-O spec/spec.opts]'
