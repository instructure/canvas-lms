#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose run --rm web node client_apps/canvas_quizzes/script/test
