#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker-compose exec -T cassandra ./wait-for-it
# wait-for-it is currently missing
# docker-compose exec -T dynamodb ./wait-for-it
for keyspace in auditors global_lookups page_views; do
  docker-compose exec -T cassandra cqlsh -e "CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

docker-compose exec -T web bundle exec rails db:create db:migrate
docker-compose exec -T web bundle exec rails runner "require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards"
