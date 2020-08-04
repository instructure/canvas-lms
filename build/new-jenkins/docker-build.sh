#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}
RUBY_PATCHSET_IMAGE=${RUBY_PATCHSET_IMAGE:-canvas-lms-ruby}
PATCHSET_TAG=${PATCHSET_TAG:-canvas-lms}
optionalFromCache=''
[[ "${SKIP_CACHE:-false}" = "false" ]] && optionalFromCache="--cache-from $MERGE_TAG"

optionalFromCacheRuby=''
[[ "${SKIP_CACHE:-false}" = "false" ]] && optionalFromCacheRuby="--cache-from $RUBY_GEMS_MERGE_IMAGE --cache-from $RUBY_GEMS_PATCHSET_IMAGE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --file ruby.Dockerfile \
  $optionalFromCacheRuby \
  --tag "$RUBY_GEMS_PATCHSET_IMAGE" \
  --target gems-only \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT" \
  --build-arg RUBY="$RUBY" \
  --file ruby.Dockerfile \
  $optionalFromCacheRuby \
  --tag "$RUBY_PATCHSET_IMAGE" \
  --target final \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --build-arg NODE="$NODE" \
  --build-arg RUBY_PATCHSET_IMAGE="$RUBY_GEMS_PATCHSET_IMAGE" \
  --file Dockerfile \
  $optionalFromCache \
  --tag "$PATCHSET_TAG" \
  "$WORKSPACE"
