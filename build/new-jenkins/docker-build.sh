#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-gems" --target cache-helper-collect-gems "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-yarn" --target cache-helper-collect-yarn "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-packages" --target cache-helper-collect-packages "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-webpack" --target cache-helper-collect-webpack "$WORKSPACE"

# shellcheck disable=SC2086
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_CACHE_TAG || true
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $CACHE_TAG || true
./build/new-jenkins/docker-with-flakey-network-protection.sh pull instructure/ruby-passenger:$RUBY

# Buildkit pulls the manifest directly from the server to avoid downloading
# the whole image. This path seems to have an issue on CI systems where the
# layers will intermittently not be reused. Usually it happens when it pulls
# the entire instructure/ruby-passenger manifest. Normal docker has a different
# code path that doesn't reproduce the error, so we skip using Buildkit here.
docker build \
  --build-arg CANVAS_RAILS6_0=${CANVAS_RAILS6_0:-0} \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --cache-from $WEBPACK_BUILDER_CACHE_TAG \
  --tag "local/webpack-builder" \
  --tag "$WEBPACK_BUILDER_CACHE_TAG" \
  ${WEBPACK_BUILDER_TAG:+ --tag "$WEBPACK_BUILDER_TAG"} \
  - < Dockerfile.jenkins

docker build \
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
  --cache-from $CACHE_TAG \
  --tag "local/webpack-runner" \
  --tag "$CACHE_TAG" \
  - < Dockerfile.jenkins.webpack-runner

if [ -n "${1:-}" ]; then
  docker build \
    --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
    --file Dockerfile.jenkins.final \
    --tag "$1" \
    "$WORKSPACE"
fi
