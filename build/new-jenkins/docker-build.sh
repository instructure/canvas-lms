#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-gems" --target cache-helper-collect-gems "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-yarn" --target cache-helper-collect-yarn "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-webpack" --target cache-helper-collect-webpack "$WORKSPACE"

# shellcheck disable=SC2086
docker pull $CACHE_TAG || true
docker pull instructure/ruby-passenger:$RUBY
docker build \
  --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
  --build-arg CANVAS_RAILS6_0=${CANVAS_RAILS6_0:-0} \
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --cache-from $CACHE_TAG \
  --file Dockerfile.jenkins \
  --tag "$1" \
  "$WORKSPACE"
