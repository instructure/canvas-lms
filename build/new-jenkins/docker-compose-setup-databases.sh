#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

PROCESSES=$((${DOCKER_PROCESSES:=1}-1))
DATABASE_PROCESSES=$((${RSPEC_PROCESSES:=1}-1))

create_cmd=""
for keyspace in auditors global_lookups page_views; do
  create_cmd+="CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T cassandra cqlsh -e \"${create_cmd[@]}\""

seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T canvas bundle exec rails db:migrate >> ./migrate-{}.log"
seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T canvas bundle exec rails runner \"require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards\""

for i in $(seq 0 $PROCESSES); do
  for keyspace in auditors global_lookups page_views; do
    seq 0 $DATABASE_PROCESSES | parallel "docker-compose --project-name canvas-lms${i} exec -T cassandra bash -c 'cqlsh -e \"DESCRIBE KEYSPACE ${keyspace}\" | sed \"s/CREATE KEYSPACE ${keyspace}/CREATE KEYSPACE ${keyspace}{}/g ; s/CREATE TABLE ${keyspace}/CREATE TABLE ${keyspace}{}/g\" > ${keyspace}{} && cqlsh -f \"${keyspace}{}\"'"
  done
done

for i in $(seq 0 $PROCESSES); do
  seq 0 $DATABASE_PROCESSES | parallel "docker-compose --project-name canvas-lms${i} exec -T postgres sh -c 'createdb -U postgres -T canvas_test canvas_test_{}'"
done
