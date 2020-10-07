#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# pull docker images (or build them if missing)

REGISTRY_BASE=starlord.inscloudgate.net/jenkins
POSTGIS=${POSTGIS:-2.5}

# canvas-lms
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $PATCHSET_TAG

# redis
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/redis:alpine

# postgres database with postgis preinstalled
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $POSTGRES_IMAGE_TAG

# cassandra:2:2
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $CASSANDRA_IMAGE_TAG

# dynamodb-local
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $DYNAMODB_IMAGE_TAG
