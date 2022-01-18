#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

export CACHE_VERSION="2020-02-02.1"

source ./build/new-jenkins/docker-build-helpers.sh

KARMA_BUILDER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.karma-builder | md5sum)

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker tag $WEBPACK_BUILDER_IMAGE local/webpack-builder

BASE_IMAGE_ID=$(docker images --filter=reference=$WEBPACK_BUILDER_IMAGE --format '{{.ID}}')

KARMA_BUILDER_PARTS=(
  $BASE_IMAGE_ID
  $KARMA_BUILDER_DOCKERFILE_MD5
)

declare -A KARMA_BUILDER_TAGS; compute_tags "KARMA_BUILDER_TAGS" $KARMA_BUILDER_PREFIX ${KARMA_BUILDER_PARTS[@]}

KARMA_BUILDER_SELECTED_TAG=""; pull_first_tag "KARMA_BUILDER_SELECTED_TAG" ${KARMA_BUILDER_TAGS[LOAD_TAG]} ${KARMA_BUILDER_TAGS[LOAD_FALLBACK_TAG]}

if [ -z "${KARMA_BUILDER_SELECTED_TAG}" ]; then
  docker build \
    --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
    --tag "${KARMA_BUILDER_TAGS[SAVE_TAG]}" \
    - < Dockerfile.jenkins.karma-builder

  KARMA_BUILDER_SELECTED_TAG=${KARMA_BUILDER_TAGS[SAVE_TAG]}

  add_log "built ${KARMA_BUILDER_SELECTED_TAG}"
fi

tag_many $KARMA_BUILDER_SELECTED_TAG local/karma-builder ${KARMA_BUILDER_TAGS[SAVE_TAG]}

docker build \
  --build-arg PATCHSET_TAG="$PATCHSET_TAG" \
  --build-arg RAILS_LOAD_ALL_LOCALES="$RAILS_LOAD_ALL_LOCALES" \
  --file Dockerfile.jenkins.karma-runner \
  --label "KARMA_BUILDER_SELECTED_TAG=$KARMA_BUILDER_SELECTED_TAG" \
  --label "PATCHSET_TAG=$PATCHSET_TAG" \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$WORKSPACE"

add_log "built $1"
