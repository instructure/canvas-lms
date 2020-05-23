#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose run --rm canvas node client_apps/canvas_quizzes/script/test
