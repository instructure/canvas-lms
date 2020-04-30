#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# pull docker images (or build them if missing)

REGISTRY_BASE=starlord.inscloudgate.net/jenkins
POSTGIS=${POSTGIS:-2.5}

# redis
docker pull $REGISTRY_BASE/redis:alpine || \
  (docker pull redis:alpine && \
  docker tag redis:alpine $REGISTRY_BASE/redis:alpine && \
  docker push $REGISTRY_BASE/redis:alpine)

# postgres database with postgis preinstalled
docker pull $REGISTRY_BASE/postgis:"$POSTGRES-$POSTGIS" || \
  (docker build -t $REGISTRY_BASE/postgis:"$POSTGRES"-"$POSTGIS" build/docker-compose/postgres && \
  docker push $REGISTRY_BASE/postgis:"$POSTGRES"-"$POSTGIS")

# cassandra:2:2
docker pull $REGISTRY_BASE/cassandra:2.2 || \
  (docker build -t $REGISTRY_BASE/cassandra:2.2 build/docker-compose/cassandra && \
  docker push $REGISTRY_BASE/cassandra:2.2)

# dynamodb-local
docker pull $REGISTRY_BASE/dynamodb-local || \
  (docker build -t $REGISTRY_BASE/dynamodb-local build/docker-compose/dynamodb && \
  docker push $REGISTRY_BASE/dynamodb-local)
