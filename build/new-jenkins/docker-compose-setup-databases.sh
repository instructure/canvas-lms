#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

DATABASE_PROCESSES=$((${RSPEC_PROCESSES:=1}-1))

create_cmd=""
for keyspace in page_views; do
  create_cmd+="CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

docker-compose exec -T cassandra cqlsh -e "${create_cmd[@]}"

docker-compose exec -T canvas bin/rails --trace db:migrate >> ./migrate.log
docker-compose exec -T canvas bin/rake ci:reset_database RAILS_ENV=test CREATE_SHARDS=1

for keyspace in page_views; do
  seq 0 $DATABASE_PROCESSES | parallel "docker-compose exec -T cassandra bash -c 'cqlsh -e \"DESCRIBE KEYSPACE ${keyspace}\" | sed \"s/CREATE KEYSPACE ${keyspace}/CREATE KEYSPACE ${keyspace}{}/g ; s/CREATE TABLE ${keyspace}/CREATE TABLE ${keyspace}{}/g\" > ${keyspace}{} && cqlsh -f \"${keyspace}{}\"'"
done

seq 0 $DATABASE_PROCESSES | parallel "docker-compose exec -T postgres sh -c 'createdb -U postgres -T canvas_test canvas_test_{}'"

