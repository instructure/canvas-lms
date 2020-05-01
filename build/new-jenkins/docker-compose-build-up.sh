#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

docker-compose build

seq 0 $((${DOCKER_PROCESSES:=1}-1)) | parallel "docker-compose --project-name canvas-lms{} up -d"
