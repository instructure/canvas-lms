#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace
# ':' is a bash "no-op" and then we pass an empty argument which isn't used
parallel --will-cite ::: :

PROCESSES=$((${DOCKER_PROCESSES:=1}-1))

create_cmd=""
for keyspace in auditors global_lookups page_views; do
  create_cmd+="CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done
seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T cassandra cqlsh -e \"${create_cmd[@]}\""

seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T -e VERBOSE=false canvas bundle exec rails db:migrate"
seq 0 $PROCESSES | parallel "docker-compose --project-name canvas-lms{} exec -T canvas bundle exec rails runner \"require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards\""
