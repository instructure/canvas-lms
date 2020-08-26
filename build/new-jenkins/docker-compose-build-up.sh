#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

PROCESSES=$((${DOCKER_PROCESSES:=1}-1))

docker-compose build

seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} up -d"

for service in cassandra:9160 postgres:5432 dynamodb:8000 redis:6379; do
  seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T canvas ./build/new-jenkins/wait-for-it ${service}"
done
