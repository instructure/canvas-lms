#!/bin/bash

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

# redis:alpine
docker pull $REGISTRY_BASE/redis:alpine || \
  (docker pull redis:alpine && \
  docker tag redis:alpine $REGISTRY_BASE/redis:alpine && \
  docker push $REGISTRY_BASE/redis:alpine)

# postgres:9.5
docker pull $REGISTRY_BASE/postgres:9.5 || \
  (docker build -t $REGISTRY_BASE/postgres:9.5 build/docker-compose/postgres/9.5 && \
  docker push $REGISTRY_BASE/postgres:9.5)

# cassandra:2:2
docker pull $REGISTRY_BASE/cassandra:2.2 || \
  (docker build -t $REGISTRY_BASE/cassandra:2.2 build/docker-compose/cassandra && \
  docker push $REGISTRY_BASE/cassandra:2.2)

# dynamodb-local
docker pull $REGISTRY_BASE/dynamodb-local || \
  (docker pull amazon/dynamodb-local && \
  docker tag amazon/dynamodb-local $REGISTRY_BASE/dynamodb-local && \
  docker push $REGISTRY_BASE/dynamodb-local)
