#!/bin/bash

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

docker pull $REGISTRY_BASE/redis:alpine || \
  (docker pull redis:alpine && \
  docker tag redis:alpine $REGISTRY_BASE/redis:alpine && \
  docker push $REGISTRY_BASE/redis:alpine)
docker pull $REGISTRY_BASE/postgres:9.5 || \
  (docker build -t $REGISTRY_BASE/postgres:9.5 build/docker-compose/postgres/9.5 && \
  docker push $REGISTRY_BASE/postgres:9.5)
docker pull $REGISTRY_BASE/cassandra:2.2 || \
  (docker build -t $REGISTRY_BASE/cassandra:2.2 build/docker-compose/cassandra && \
  docker push $REGISTRY_BASE/cassandra:2.2)
