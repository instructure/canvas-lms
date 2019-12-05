#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# -O spec/spec.opts runs rspec with our formatters for failure reports
docker-compose exec -T web bundle exec rspec --options spec/spec.opts spec/selenium/login_logout_spec.rb
