#!/usr/bin/env bash

WORKSPACE=${WORKSPACE:-$(pwd)}

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

source ./build/new-jenkins/docker-build-helpers.sh

while docker exec -t general-build-container ps aww | grep graphql; do
  sleep 0.1
done

mkdir -p tmp
docker cp $(docker ps -qa -f name=general-build-container):/usr/src/app/schema.graphql tmp/schema.graphql

DOCKER_BUILDKIT=1 docker build \
  --file Dockerfile.jenkins.js \
  --label "PATCHSET_TAG=$PATCHSET_TAG" \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$WORKSPACE/tmp"

add_log "built $1"
