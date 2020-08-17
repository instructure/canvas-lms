#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}
RUBY_PATCHSET_IMAGE=${RUBY_PATCHSET_IMAGE:-canvas-lms-ruby}
PATCHSET_TAG=${PATCHSET_TAG:-canvas-lms}

dependencyArgs=(
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR"
  --build-arg BUILDKIT_INLINE_CACHE=1
  --build-arg NODE="$NODE"
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT"
  --build-arg RUBY="$RUBY"
  --file Dockerfile.jenkins
)

if [[ "${SKIP_CACHE:-false}" = "false" ]]; then
  dependencyArgs+=("--cache-from $DEPENDENCIES_MERGE_IMAGE")
fi

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  ${dependencyArgs[@]} \
  --tag "$DEPENDENCIES_PATCHSET_IMAGE" \
  --target dependencies \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  ${dependencyArgs[@]} \
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
  --tag "$PATCHSET_TAG" \
  --target webpack-final \
  "$WORKSPACE"
