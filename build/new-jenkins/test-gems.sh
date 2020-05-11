#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose --project-name canvas-lms0 exec -T canvas ./gems/test_all_gems.sh
