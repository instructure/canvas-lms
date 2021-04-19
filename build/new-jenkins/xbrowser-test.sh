#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose --project-name canvas-lms0 exec -T canvas bundle exec rspec --options spec/spec.opts --tag xbrowser spec/selenium/
