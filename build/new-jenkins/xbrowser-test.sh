#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose exec -T web bundle exec rspec --options spec/spec.opts --tag xbrowser spec/selenium/
