#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

export DATABASE_NAME=canvas_test0

docker-compose build
docker-compose up -d
