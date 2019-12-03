#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose run --name tests-packages -e COVERAGE web yarn test:packages
