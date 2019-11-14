#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

docker-compose exec -T cassandra ./wait-for-it
# wait-for-it is currently missing
# docker-compose exec -T dynamodb ./wait-for-it
for keyspace in auditors global_lookups page_views; do
  docker-compose exec -T cassandra cqlsh -e "CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

(docker-compose exec -T web bundle exec rails db:create db:migrate > /tmp/possible_migration_error.txt 2>&1; cat /tmp/possible_migration_error.txt) && rm /tmp/possible_migration_error.txt
docker-compose exec -T web script/rails runner "require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards"
