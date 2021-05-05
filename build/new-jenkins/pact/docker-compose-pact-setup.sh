#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace
# ':' is a bash "no-op"
parallel --will-cite ::: :

DATABASE_PROCESSES=$((${RSPEC_PROCESSES:=1}-1))

# build and start services
docker-compose build --parallel canvas cassandra postgres redis
docker-compose up -d canvas cassandra postgres redis

# wait for services to respond
docker-compose exec -T postgres /bin/bash -c /wait-for-it

for service in cassandra:9160 redis:6379; do
  docker-compose exec -T canvas ./build/new-jenkins/wait-for-it ${service}
done

# clone databases from canvas_test
seq 0 $DATABASE_PROCESSES | parallel "docker-compose exec -T postgres sh -c 'createdb -U postgres -T canvas_test pact_test{}'"
