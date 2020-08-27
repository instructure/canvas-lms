#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace

sha="$(git rev-parse --short HEAD)"
docker-compose run --no-deps --rm -e SHA="${sha}" \
  -e PACT_BROKER_HOST=inst-pact-broker.inseng.net \
  -e PACT_BROKER_USERNAME="${PACT_BROKER_USERNAME}" \
  -e PACT_BROKER_PASSWORD="${PACT_BROKER_PASSWORD}" \
  canvas bundle exec rake broker:pact:publish:jenkins_post_merge
