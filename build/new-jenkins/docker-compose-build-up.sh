#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose build
docker-compose up -d
for config_name in database cassandra security dynamodb; do
  docker-compose exec -T web cp config/new-jenkins/${config_name}.yml config/${config_name}.yml
done
