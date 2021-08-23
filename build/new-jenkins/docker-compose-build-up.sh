#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose build
docker-compose up -d

for service in cassandra:9160  dynamodb:8000 redis:6379; do
  docker-compose exec -T canvas ./build/new-jenkins/wait-for-it ${service}
done

docker-compose exec -T postgres /bin/bash -c /wait-for-it
