#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}
CRYSTALBALL_MAP=${CRYSTALBALL_MAP:-0}

echo "CRYSTALBALL_MAP VALUE ${CRYSTALBALL_MAP}"

export CACHE_VERSION="2022-08-15.1"

source ./build/new-jenkins/docker-build-helpers.sh

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker tag $WEBPACK_BUILDER_IMAGE local/webpack-builder

BASE_IMAGE_ID=$(docker images --filter=reference=$WEBPACK_BUILDER_IMAGE --format '{{.ID}}')

while docker exec -t general-build-container ps aww | grep graphql; do
  sleep 0.1
done

docker cp $(docker ps -qa -f name=general-build-container):/usr/src/app/schema.graphql ./schema.graphql

docker build \
  --build-arg PATCHSET_TAG="$PATCHSET_TAG" \
  --file Dockerfile.jenkins.karma-runner \
  --label "PATCHSET_TAG=$PATCHSET_TAG" \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$WORKSPACE"

add_log "built $1"
