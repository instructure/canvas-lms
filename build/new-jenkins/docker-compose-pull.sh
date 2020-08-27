#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# pull docker images (or build them if missing)

REGISTRY_BASE=starlord.inscloudgate.net/jenkins
POSTGIS=${POSTGIS:-2.5}

# canvas-lms
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $PATCHSET_TAG

# redis
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/redis:alpine || \
  (./build/new-jenkins/docker-with-flakey-network-protection.sh pull redis:alpine && \
  docker tag redis:alpine $REGISTRY_BASE/redis:alpine && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $REGISTRY_BASE/redis:alpine)

# postgres database with postgis preinstalled
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $POSTGRES_IMAGE_TAG || \
  (docker build -t $POSTGRES_IMAGE_TAG --build-arg POSTGRES="$POSTGRES" build/docker-compose/postgres && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $POSTGRES_IMAGE_TAG)

# cassandra:2:2
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $CASSANDRA_IMAGE_TAG || \
  (docker build -f build/docker-compose/cassandra/Dockerfile.cachable -t $CASSANDRA_IMAGE_TAG build/docker-compose/cassandra && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $CASSANDRA_IMAGE_TAG)

# dynamodb-local
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $DYNAMODB_IMAGE_TAG || \
  (docker build -t $DYNAMODB_IMAGE_TAG build/docker-compose/dynamodb && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $DYNAMODB_IMAGE_TAG)
