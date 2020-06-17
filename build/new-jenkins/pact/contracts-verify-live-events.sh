#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o xtrace

docker-compose run --name live_events --no-deps \
  -e RAILS_ENV=test \
  -e PACT_BROKER_HOST=inst-pact-broker.inseng.net \
  -e PACT_BROKER_USERNAME="${PACT_BROKER_USERNAME}" \
  -e PACT_BROKER_PASSWORD="${PACT_BROKER_PASSWORD}" \
  canvas bundle exec rspec spec/contracts/service_consumers/live_events \
    --tag pact_live_events --format doc
