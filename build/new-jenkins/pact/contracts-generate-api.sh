#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace

docker-compose run --name ${DATABASE_NAME} -T \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/${DATABASE_NAME} \
  canvas bundle exec rspec spec/contracts/service_providers/ \
    --tag pact --format doc

if [[ "$PUBLISH_API" == "1" ]]; then
  sha="$(git rev-parse --short HEAD)"
  docker-compose run --no-deps --rm -e SHA="${sha}" \
    -e PACT_BROKER_HOST=inst-pact-broker.inseng.net \
    -e PACT_BROKER_USERNAME="${PACT_BROKER_USERNAME}" \
    -e PACT_BROKER_PASSWORD="${PACT_BROKER_PASSWORD}" \
    canvas bundle exec rake broker:pact:publish:jenkins_post_merge
fi
