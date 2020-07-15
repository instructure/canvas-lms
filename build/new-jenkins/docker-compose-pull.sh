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
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/postgis:"$POSTGRES-$POSTGIS" || \
  (docker build -t $REGISTRY_BASE/postgis:"$POSTGRES"-"$POSTGIS" build/docker-compose/postgres && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $REGISTRY_BASE/postgis:"$POSTGRES"-"$POSTGIS")

# cassandra:2:2
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/cassandra:2.2 || \
  (docker build -t $REGISTRY_BASE/cassandra:2.2 build/docker-compose/cassandra && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $REGISTRY_BASE/cassandra:2.2)

# dynamodb-local
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/dynamodb-local || \
  (docker build -t $REGISTRY_BASE/dynamodb-local build/docker-compose/dynamodb && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $REGISTRY_BASE/dynamodb-local)
