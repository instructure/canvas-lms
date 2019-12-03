#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose run --name tests-jest -e COVERAGE web yarn test:jest --runInBand
