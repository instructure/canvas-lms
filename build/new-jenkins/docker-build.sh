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
# $WEBPACK_CACHE_LOAD_SCOPE: image prefix for the primary cache image to load
# $WEBPACK_CACHE_SAVE_SCOPE: image prefix for the target tag and also the secondary cache image to load

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

# Calculate the MD5SUM of all images / files that compiled webpack assets depend on.
BASE_IMAGE_ID=$(docker images --filter=reference=local/ruby-runner --format '{{.ID}}')
DOCKERFILE_CACHE_MD5=$( \
  cat \
    Dockerfile.jenkins.webpack-builder \
    Dockerfile.jenkins.webpack-runner \
    Dockerfile.jenkins.webpack-cache \
  | md5sum | cut -d ' ' -f 1 \
)
YARN_CACHE_MD5=$(docker run local/cache-helper-collect-yarn sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1")
PACKAGES_CACHE_MD5=$(docker run local/cache-helper-collect-packages sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1")
WEBPACK_CACHE_MD5=$(docker run local/cache-helper-collect-webpack sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum | cut -d ' ' -f 1")

WEBPACK_CACHE_ID=$(echo "$BASE_IMAGE_ID $DOCKERFILE_CACHE_MD5 $YARN_CACHE_MD5 $PACKAGES_CACHE_MD5 $WEBPACK_CACHE_MD5" | md5sum | cut -d' ' -f1)
WEBPACK_CACHE_SAVE_TAG="$WEBPACK_CACHE_PREFIX:$WEBPACK_CACHE_SAVE_SCOPE-$WEBPACK_CACHE_ID"
WEBPACK_CACHE_LOAD_TAG="$WEBPACK_CACHE_PREFIX:${WEBPACK_CACHE_LOAD_SCOPE:-$WEBPACK_CACHE_SAVE_SCOPE}-$WEBPACK_CACHE_ID"

# Build / Load Webpack Image
WEBPACK_CACHE_SELECTED_TAG=""

if ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_CACHE_LOAD_TAG; then
  # Optimize for changes that don't require webpack to re-build. Pull the image that is shared
  # across all patchsets.
  WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_LOAD_TAG

  docker tag $WEBPACK_CACHE_SELECTED_TAG local/webpack-cache
elif ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_CACHE_SAVE_TAG; then
  WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_SAVE_TAG

  docker tag $WEBPACK_CACHE_SELECTED_TAG local/webpack-cache
else
  # If any webpack-related file has changed, we need to pull $WEBPACK_BUILDER_CACHE_TAG and rebuild.
  ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_CACHE_TAG || true

  docker build \
    --cache-from $WEBPACK_BUILDER_CACHE_TAG \
    --tag "local/webpack-builder" \
    --tag "$WEBPACK_BUILDER_CACHE_TAG" \
    ${WEBPACK_BUILDER_TAG:+ --tag "$WEBPACK_BUILDER_TAG"} \
    - < Dockerfile.jenkins.webpack-builder

  docker build \
    --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
    --tag "local/webpack-runner" \
    - < Dockerfile.jenkins.webpack-runner

  docker build \
    --tag "local/webpack-cache" \
    --tag "$WEBPACK_CACHE_SAVE_TAG" \
    - < Dockerfile.jenkins.webpack-cache

  WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_SAVE_TAG
fi

# Build Final Image
if [ -n "${1:-}" ]; then
  docker build \
    --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
    --file Dockerfile.jenkins.final \
    --label "WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_SELECTED_TAG" \
    --tag "$1" \
    "$WORKSPACE"
fi
