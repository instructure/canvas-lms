#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace

docker-compose run --name ${DATABASE_NAME} -T \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/${DATABASE_NAME} \
  canvas bundle exec rspec spec/contracts/service_providers/ \
    --tag pact --format doc
