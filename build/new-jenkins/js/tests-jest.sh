#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose run --name tests-jest -e COVERAGE -e RAILS_ENV=test web \
    bash -c "bundle exec rails graphql:schema && yarn test:jest --runInBand"
