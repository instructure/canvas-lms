#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

CANVAS_HOST=${CANVAS_HOST:-"localhost:8181"}
export COMPOSE_FILE='docker-compose.new-jenkins.consumer.yml'

./build/new-jenkins/docker-compose-pull.sh

docker-compose up -d
docker-compose run -T canvas bundle exec rails db:create db:migrate

docker ps

containers=($(docker-compose ps -q))
if [[ "${#containers[@]}" != 4 ]]; then
  echo "not the correct amount of containers started"
  exit 1
fi

for service in "${containers[@]}"
do
  if [[ "`docker inspect --format '{{.State.Status}}' $service`" != 'running' ]]; then
    exit 1
  fi
done

curl --head --fail http://$CANVAS_HOST/health_check.json

