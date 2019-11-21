#!/bin/bash

docker-compose exec -T cassandra ./wait-for-it
for keyspace in auditors global_lookups page_views; do
  docker-compose exec -T cassandra cqlsh -e "CREATE KEYSPACE ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

docker-compose exec -T web bundle exec rails db:create
