#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

dependencyArgs=(
  --build-arg BUILDKIT_INLINE_CACHE=1
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT"
  --build-arg RUBY="$RUBY"
  --file Dockerfile.jenkins
)

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 PROGRESS_NO_TRUNC=1 docker build \
  --pull \
  ${dependencyArgs[@]} \
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
  --cache-from $CACHE_TAG \
  --tag "$1" \
  --target webpack-final \
  "$WORKSPACE"
