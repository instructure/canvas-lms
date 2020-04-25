#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose exec -T web ./build/new-jenkins/wait-for-it cassandra:9160
create_cmd=""
for keyspace in auditors global_lookups page_views; do
  create_cmd+="CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done
docker-compose exec -T cassandra cqlsh -e "${create_cmd[@]}"

# migrations cannot complete until postgres, dynamodb, and cassandra are up.
# (cassandra was verified above) redis is included here for completion but
# isn't necessary for migrations
for service in postgres:5432 dynamodb:8000 redis:6379; do
  docker-compose exec -T web ./build/new-jenkins/wait-for-it ${service}
done

docker-compose exec -T -e VERBOSE=false web bundle exec rails db:migrate
docker-compose exec -T web bundle exec rails runner "require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards"
