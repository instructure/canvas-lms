#!/bin/bash

docker-compose build
docker-compose up -d
for config_name in database cassandra security; do
  docker-compose exec -T web cp config/new-jenkins/${config_name}.yml config/${config_name}.yml
done

