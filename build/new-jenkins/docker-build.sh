#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

# Some of these steps look like they could be done better using a multi-stage
# build or buildkit. Be careful when doing this, we encountered several issues
# where using these newer tools resulted in the cache not being used at all on
# our CI system.
# 1. When using a multi-stage build, only the first stage was cached. We were
#    unable to get the CI system to use cached layers from any subsequent stage.
# 2. When using buildkit, the entire cache would be intermittently not reused.
#    It seemed to happen if Buildkit also pulled the instructure/ruby-passenger
#    image manifest before pulling the image layers.
# 3. When using buildkit, modifying a layer could result in the cache for previous
#    layers not being used, even when their contents have not changed.

# Images:
# $RUBY_RUNNER_TAG: instructure/ruby-passenger + gems
# $WEBPACK_BUILDER_TAG: $RUBY_RUNNER_TAG + yarn + compiled packages/
# $WEBPACK_CACHE_TAG: $RUBY_RUNNER_TAG + final compiled assets
# $1: final image for this build, including all rails code

# Controls:
# $CACHE_LOAD_SCOPE: the scope of the primary cache to load.
#   - typically "master" for post-merge builds and <patchset_number> for pre-merge builds
# $CACHE_LOAD_FALLBACK_SCOPE: the fallback scope if the primary scope doesn't exist
#   - typically <patchset_number> for all builds.
#   - pre-merge builds use this to cache re-trigger attempts and for new revisions without code changes
#   - post-merge builds use this to pull images from previous pre-merge builds in case it is already built
# $CACHE_SAVE_SCOPE: the scope to save the image under
#   - always "master" for post-merge builds and <patchset_number> for pre-merge builds

source ./build/new-jenkins/docker-build-helpers.sh

DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-gems" --target cache-helper-collect-gems "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-yarn" --target cache-helper-collect-yarn "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-packages" --target cache-helper-collect-packages "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-webpack" --target cache-helper-collect-webpack "$WORKSPACE"

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $RUBY_RUNNER_TAG || true
# Explicitly pull instructure/ruby-passenger to update the local tag in case $RUBY_RUNNER_TAG is
# using a new version. If this doesn't happen, the cache isn't used because Docker thinks the base
# image is different.
./build/new-jenkins/docker-with-flakey-network-protection.sh pull instructure/ruby-passenger:$RUBY

docker build \
  --build-arg CANVAS_RAILS6_0=${CANVAS_RAILS6_0:-0} \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --cache-from $RUBY_RUNNER_TAG \
  --tag "local/ruby-runner" \
  --tag "$RUBY_RUNNER_TAG" \
  - < Dockerfile.jenkins

# Calculate Cache ID For webpack-cache
RUBY_RUNNER_IMAGE_ID=$(docker images --filter=reference=local/ruby-runner --format '{{.ID}}')
YARN_CACHE_MD5=$(docker run local/cache-helper-collect-yarn sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
PACKAGES_CACHE_MD5=$(docker run local/cache-helper-collect-packages sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
WEBPACK_CACHE_MD5=$(docker run local/cache-helper-collect-webpack sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
YARN_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.yarn-runner | md5sum)
WEBPACK_BUILDER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-builder | md5sum)
WEBPACK_CACHE_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-cache | md5sum)

WEBPACK_CACHE_BUILD_ARGS=(
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY"
)
YARN_RUNNER_PARTS=(
  $RUBY_RUNNER_IMAGE_ID
  $YARN_RUNNER_DOCKERFILE_MD5
  $YARN_CACHE_MD5
)
WEBPACK_BUILDER_PARTS=(
  "${YARN_RUNNER_PARTS[@]}"
  $WEBPACK_BUILDER_DOCKERFILE_MD5
  $PACKAGES_CACHE_MD5
)
WEBPACK_CACHE_PARTS=(
  "${WEBPACK_BUILDER_PARTS[@]}"
  "${WEBPACK_CACHE_BUILD_ARGS[@]}"
  $WEBPACK_CACHE_DOCKERFILE_MD5
  $WEBPACK_CACHE_MD5
)
declare -A WEBPACK_CACHE_TAGS; compute_tags "WEBPACK_CACHE_TAGS" $WEBPACK_CACHE_PREFIX ${WEBPACK_CACHE_PARTS[@]}

# Build / Load Webpack Image
WEBPACK_CACHE_SELECTED_TAG=""; pull_first_tag "WEBPACK_CACHE_SELECTED_TAG" ${WEBPACK_CACHE_TAGS[LOAD_TAG]} ${WEBPACK_CACHE_TAGS[LOAD_FALLBACK_TAG]}

if [ -z "${WEBPACK_CACHE_SELECTED_TAG}" ]; then
  declare -A WEBPACK_BUILDER_TAGS; compute_tags "WEBPACK_BUILDER_TAGS" $WEBPACK_BUILDER_PREFIX ${WEBPACK_BUILDER_PARTS[@]}

  WEBPACK_BUILDER_SELECTED_TAG=""; pull_first_tag "WEBPACK_BUILDER_SELECTED_TAG" ${WEBPACK_BUILDER_TAGS[LOAD_TAG]} ${WEBPACK_BUILDER_TAGS[LOAD_FALLBACK_TAG]}

  if [ -z "${WEBPACK_BUILDER_SELECTED_TAG}" ]; then
    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $YARN_RUNNER_CACHE_TAG || true

    docker build \
      --cache-from $YARN_RUNNER_CACHE_TAG \
      --tag "local/yarn-runner" \
      --tag "$YARN_RUNNER_CACHE_TAG" \
      - < Dockerfile.jenkins.yarn-runner

    docker build \
      --tag "${WEBPACK_BUILDER_TAGS[SAVE_TAG]}" \
      ${WEBPACK_BUILDER_TAG:+ --tag "$WEBPACK_BUILDER_TAG"} \
      - < Dockerfile.jenkins.webpack-builder

    WEBPACK_BUILDER_SELECTED_TAG=${WEBPACK_BUILDER_TAGS[SAVE_TAG]}
  fi

  tag_many $WEBPACK_BUILDER_SELECTED_TAG local/webpack-builder ${WEBPACK_BUILDER_TAGS[SAVE_TAG]}

  # Using a multi-stage build is safe for the below image because
  # there is no expectation that we will need to use docker's
  # built-in caching.
  docker build \
    "${WEBPACK_CACHE_BUILD_ARGS[@]}" \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --tag "${WEBPACK_CACHE_TAGS[SAVE_TAG]}" \
    --target webpack-cache \
    - < Dockerfile.jenkins.webpack-cache

  WEBPACK_CACHE_SELECTED_TAG=${WEBPACK_CACHE_TAGS[SAVE_TAG]}
else
  WEBPACK_BUILDER_SELECTED_TAG=$(docker inspect $WEBPACK_CACHE_SELECTED_TAG --format '{{ .Config.Labels.WEBPACK_BUILDER_SELECTED_TAG }}')
fi

tag_many $WEBPACK_CACHE_SELECTED_TAG local/webpack-cache ${WEBPACK_CACHE_TAGS[SAVE_TAG]}

# Build Final Image
if [ -n "${1:-}" ]; then
  docker build \
    --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
    --file Dockerfile.jenkins.final \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --label "WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_SELECTED_TAG" \
    --tag "$1" \
    "$WORKSPACE"
fi
