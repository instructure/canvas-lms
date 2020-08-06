#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}
RUBY_PATCHSET_IMAGE=${RUBY_PATCHSET_IMAGE:-canvas-lms-ruby}
PATCHSET_TAG=${PATCHSET_TAG:-canvas-lms}

optionalFromCache=''
[[ "${SKIP_CACHE:-false}" = "false" ]] && optionalFromCache="--cache-from $RUBY_GEMS_MERGE_IMAGE --cache-from $RUBY_GEMS_PATCHSET_IMAGE --cache-from $MERGE_TAG"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --file Dockerfile \
  $optionalFromCache \
  --tag "$RUBY_GEMS_PATCHSET_IMAGE" \
  --target ruby-gems-only \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --file Dockerfile \
  $optionalFromCache \
  --tag "$RUBY_PATCHSET_IMAGE" \
  --target ruby-final \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg NODE="$NODE" \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --file Dockerfile \
  $optionalFromCache \
  --tag "$PATCHSET_TAG" \
  --target webpack-final \
  "$WORKSPACE"
