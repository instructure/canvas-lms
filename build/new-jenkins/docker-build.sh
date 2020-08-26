#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}
RUBY_PATCHSET_IMAGE=${RUBY_PATCHSET_IMAGE:-canvas-lms-ruby}
PATCHSET_TAG=${PATCHSET_TAG:-canvas-lms}

commonRubyArgs=(
  --build-arg ALPINE_MIRROR="$ALPINE_MIRROR"
  --build-arg BUILDKIT_INLINE_CACHE=1
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT"
  --build-arg RUBY="$RUBY"
  --file Dockerfile
)

commonNodeArgs=(
  --build-arg NODE="$NODE"
)

if [[ "${SKIP_CACHE:-false}" = "false" ]]; then
  commonRubyArgs+=("--cache-from $RUBY_GEMS_MERGE_IMAGE")
  commonNodeArgs+=("--cache-from $YARN_MERGE_IMAGE")
fi

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  ${commonRubyArgs[@]} \
  --tag "$RUBY_GEMS_PATCHSET_IMAGE" \
  --target ruby-gems-only \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  --pull \
  ${commonRubyArgs[@]} \
  --tag "$RUBY_PATCHSET_IMAGE" \
  --target ruby-final \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  ${commonRubyArgs[@]} \
  ${commonNodeArgs[@]} \
  --tag "$YARN_PATCHSET_IMAGE" \
  --target yarn-only \
  "$WORKSPACE"

# shellcheck disable=SC2086
DOCKER_BUILDKIT=1 docker build \
  ${commonRubyArgs[@]} \
  ${commonNodeArgs[@]} \
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY" \
  --tag "$PATCHSET_TAG" \
  --target webpack-final \
  "$WORKSPACE"
