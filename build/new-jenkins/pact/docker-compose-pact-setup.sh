#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace
# ':' is a bash "no-op"
parallel --will-cite ::: :

# build and start services
docker-compose build --parallel canvas cassandra postgres redis
docker-compose up -d canvas cassandra postgres redis

# wait for services to respond
docker-compose exec -T postgres /bin/bash -c /wait-for-it

for service in cassandra:9160 redis:6379; do
  docker-compose exec -T canvas ./build/new-jenkins/wait-for-it ${service}
done

# create cassandra keyspaces later to be used by canvas
create_cmd=""
for keyspace in auditors global_lookups page_views; do
  create_cmd+="CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done
docker-compose exec -T cassandra cqlsh -e "${create_cmd[@]}"

# migrate canvas test db
docker-compose exec -T -e VERBOSE=false canvas bundle exec rails db:migrate

# clone databases from canvas_test
seq $((DOCKER_PROCESSES-1)) | parallel "docker-compose exec -T postgres sh -c 'createdb -U postgres -T canvas_test pact_test{}'"
