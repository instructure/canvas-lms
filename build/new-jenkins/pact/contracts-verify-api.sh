#!/bin/bash

set -o errexit -o errtrace -o pipefail -o xtrace

docker-compose run -T \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/${DATABASE_NAME} \
  -e RUN_API_CONTRACT_TESTS=1 \
  -e PACT_API_CONSUMER="${PACT_API_CONSUMER}" \
  -e PACT_BROKER_HOST=inst-pact-broker.inseng.net \
  -e PACT_BROKER_USERNAME="${PACT_BROKER_USERNAME}" \
  -e PACT_BROKER_PASSWORD="${PACT_BROKER_PASSWORD}" \
  -e JENKINS_URL="this silliness is necessary." \
  -e DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true \
  canvas bundle exec rake pact:verify
