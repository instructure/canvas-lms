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
# $RUBY_RUNNER_PREFIX: instructure/ruby-passenger + gems
# $YARN_RUNNER_PREFIX: $RUBY_RUNNER_PREFIX + yarn
# $WEBPACK_BUILDER_PREFIX: $YARN_RUNNER_PREFIX + compiled packages/
# $WEBPACK_CACHE_PREFIX: $RUBY_RUNNER_PREFIX + final compiled assets
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
# $WEBPACK_BUILDER_TAG: additional tag for the webpack-builder image
#   - set to patchset unique ID for builds to reference without knowing about the hash ID

source ./build/new-jenkins/docker-build-helpers.sh

DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-gems" --target cache-helper-collect-gems "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-yarn" --target cache-helper-collect-yarn "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-packages" --target cache-helper-collect-packages "$WORKSPACE"
DOCKER_BUILDKIT=1 docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper-collect-webpack" --target cache-helper-collect-webpack "$WORKSPACE"

RUBY_CACHE_MD5=$(docker run local/cache-helper-collect-gems sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
YARN_CACHE_MD5=$(docker run local/cache-helper-collect-yarn sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
PACKAGES_CACHE_MD5=$(docker run local/cache-helper-collect-packages sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")
WEBPACK_CACHE_MD5=$(docker run local/cache-helper-collect-webpack sh -c "find /tmp/dst -type f -exec md5sum {} \; | sort -k 2 | md5sum")

RUBY_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins | md5sum)
YARN_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.yarn-runner | md5sum)
WEBPACK_BUILDER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-builder | md5sum)
WEBPACK_CACHE_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-cache | md5sum)

./build/new-jenkins/docker-with-flakey-network-protection.sh pull instructure/ruby-passenger:$RUBY

BASE_IMAGE_ID=$(docker images --filter=reference=instructure/ruby-passenger:$RUBY --format '{{.ID}}')

RUBY_RUNNER_BUILD_ARGS=(
  --build-arg CANVAS_RAILS6_0=${CANVAS_RAILS6_0:-0}
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT"
  --build-arg RUBY="$RUBY"
)
WEBPACK_CACHE_BUILD_ARGS=(
  --build-arg JS_BUILD_NO_UGLIFY="$JS_BUILD_NO_UGLIFY"
)
RUBY_RUNNER_PARTS=(
  $BASE_IMAGE_ID
  "${RUBY_RUNNER_BUILD_ARGS[@]}"
  $RUBY_RUNNER_DOCKERFILE_MD5
  $RUBY_CACHE_MD5
)
YARN_RUNNER_PARTS=(
  "${RUBY_RUNNER_PARTS[@]}"
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

declare -A RUBY_RUNNER_TAGS; compute_tags "RUBY_RUNNER_TAGS" $RUBY_RUNNER_PREFIX ${RUBY_RUNNER_PARTS[@]}
declare -A YARN_RUNNER_TAGS; compute_tags "YARN_RUNNER_TAGS" $YARN_RUNNER_PREFIX ${YARN_RUNNER_PARTS[@]}
declare -A WEBPACK_BUILDER_TAGS; compute_tags "WEBPACK_BUILDER_TAGS" $WEBPACK_BUILDER_PREFIX ${WEBPACK_BUILDER_PARTS[@]}
declare -A WEBPACK_CACHE_TAGS; compute_tags "WEBPACK_CACHE_TAGS" $WEBPACK_CACHE_PREFIX ${WEBPACK_CACHE_PARTS[@]}

WEBPACK_CACHE_SELECTED_TAG=""; pull_first_tag "WEBPACK_CACHE_SELECTED_TAG" ${WEBPACK_CACHE_TAGS[LOAD_TAG]} ${WEBPACK_CACHE_TAGS[LOAD_FALLBACK_TAG]}

if [ -z "${WEBPACK_CACHE_SELECTED_TAG}" ]; then
  WEBPACK_BUILDER_SELECTED_TAG=""; pull_first_tag "WEBPACK_BUILDER_SELECTED_TAG" ${WEBPACK_BUILDER_TAGS[LOAD_TAG]} ${WEBPACK_BUILDER_TAGS[LOAD_FALLBACK_TAG]}

  if [ -z "${WEBPACK_BUILDER_SELECTED_TAG}" ]; then
    YARN_RUNNER_SELECTED_TAG=""; pull_first_tag "YARN_RUNNER_SELECTED_TAG" ${YARN_RUNNER_TAGS[LOAD_TAG]} ${YARN_RUNNER_TAGS[LOAD_FALLBACK_TAG]}

    if [ -z "${YARN_RUNNER_SELECTED_TAG}" ]; then
      RUBY_RUNNER_SELECTED_TAG=""; pull_first_tag "RUBY_RUNNER_SELECTED_TAG" ${RUBY_RUNNER_TAGS[LOAD_TAG]} ${RUBY_RUNNER_TAGS[LOAD_FALLBACK_TAG]}

      if [ -z "${RUBY_RUNNER_SELECTED_TAG}" ]; then
        docker build \
          "${RUBY_RUNNER_BUILD_ARGS[@]}" \
          --tag "${RUBY_RUNNER_TAGS[SAVE_TAG]}" \
          - < Dockerfile.jenkins

        RUBY_RUNNER_SELECTED_TAG=${RUBY_RUNNER_TAGS[SAVE_TAG]}

        add_log "built ${RUBY_RUNNER_SELECTED_TAG}"
      fi

      tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}

      docker build \
        --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
        --tag "${YARN_RUNNER_TAGS[SAVE_TAG]}" \
        - < Dockerfile.jenkins.yarn-runner

      YARN_RUNNER_SELECTED_TAG=${YARN_RUNNER_TAGS[SAVE_TAG]}

      add_log "built ${YARN_RUNNER_SELECTED_TAG}"
    else
      RUBY_RUNNER_SELECTED_TAG=$(docker inspect $YARN_RUNNER_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')

      ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $RUBY_RUNNER_SELECTED_TAG
      tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}
    fi

    tag_many $YARN_RUNNER_SELECTED_TAG local/yarn-runner ${YARN_RUNNER_TAGS[SAVE_TAG]}

    docker build \
      --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
      --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
      --tag "${WEBPACK_BUILDER_TAGS[SAVE_TAG]}" \
      ${WEBPACK_BUILDER_TAG:+ --tag "$WEBPACK_BUILDER_TAG"} \
      - < Dockerfile.jenkins.webpack-builder

    WEBPACK_BUILDER_SELECTED_TAG=${WEBPACK_BUILDER_TAGS[SAVE_TAG]}

    add_log "built ${WEBPACK_BUILDER_SELECTED_TAG}"
  else
    RUBY_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_BUILDER_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')
    YARN_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_BUILDER_SELECTED_TAG --format '{{ .Config.Labels.YARN_RUNNER_SELECTED_TAG }}')

    # If we're here, that means webpack-builder was re-used, so we need to ensure
    # that the ancestor images are correctly tagged.
    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $YARN_RUNNER_SELECTED_TAG
    tag_many $YARN_RUNNER_SELECTED_TAG local/yarn-runner ${YARN_RUNNER_TAGS[SAVE_TAG]}

    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $RUBY_RUNNER_SELECTED_TAG
    tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}
  fi

  tag_many $WEBPACK_BUILDER_SELECTED_TAG local/webpack-builder ${WEBPACK_BUILDER_TAGS[SAVE_TAG]}

  # Using a multi-stage build is safe for the below image because
  # there is no expectation that we will need to use docker's
  # built-in caching.
  docker build \
    "${WEBPACK_CACHE_BUILD_ARGS[@]}" \
    --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
    --tag "${WEBPACK_CACHE_TAGS[SAVE_TAG]}" \
    --target webpack-cache \
    - < Dockerfile.jenkins.webpack-cache

  WEBPACK_CACHE_SELECTED_TAG=${WEBPACK_CACHE_TAGS[SAVE_TAG]}

  add_log "built ${WEBPACK_CACHE_SELECTED_TAG}"
else
  RUBY_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_CACHE_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')
  YARN_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_CACHE_SELECTED_TAG --format '{{ .Config.Labels.YARN_RUNNER_SELECTED_TAG }}')
  WEBPACK_BUILDER_SELECTED_TAG=$(docker inspect $WEBPACK_CACHE_SELECTED_TAG --format '{{ .Config.Labels.WEBPACK_BUILDER_SELECTED_TAG }}')
fi

tag_many $WEBPACK_CACHE_SELECTED_TAG local/webpack-cache ${WEBPACK_CACHE_TAGS[SAVE_TAG]}

# Build Final Image
if [ -n "${1:-}" ]; then
  docker build \
    --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
    --file Dockerfile.jenkins.final \
    --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --label "WEBPACK_CACHE_SELECTED_TAG=$WEBPACK_CACHE_SELECTED_TAG" \
    --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
    --tag "$1" \
    "$WORKSPACE"

  add_log "built $1"
fi
