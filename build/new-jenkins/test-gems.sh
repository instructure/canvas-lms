#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose exec -T web ./gems/test_all_gems.sh
