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
#    It seemed to happen if Buildkit also pulled the starlord.inscloudgate.net/jenkins/ruby-passenger
#    image manifest before pulling the image layers.
# 3. When using buildkit, modifying a layer could result in the cache for previous
#    layers not being used, even when their contents have not changed.

# Images:
# $BASE_RUNNER_PREFIX: starlord.inscloudgate.net/jenkins/ruby-passenger + additional packages
# $RUBY_RUNNER_PREFIX: $BASE_RUNNER_PREFIX + gems
# $YARN_RUNNER_PREFIX: $RUBY_RUNNER_PREFIX + yarn
# $WEBPACK_BUILDER_PREFIX: $YARN_RUNNER_PREFIX + compiled packages/
# $WEBPACK_ASSETS_PREFIX: $RUBY_RUNNER_PREFIX + final compiled assets
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

export CACHE_VERSION="2023-04-05.1"
export DOCKER_BUILDKIT=1

if [[ "$WRITE_BUILD_CACHE" == "1" ]]; then
  export USE_BUILD_CACHE=1
fi

source ./build/new-jenkins/docker-build-helpers.sh

./build/new-jenkins/docker-with-flakey-network-protection.sh pull starlord.inscloudgate.net/jenkins/dockerfile:1.5.2
./build/new-jenkins/docker-with-flakey-network-protection.sh pull starlord.inscloudgate.net/jenkins/core:focal

docker build --file Dockerfile.jenkins-cache --tag "local/cache-helper" "$WORKSPACE"

source <(docker run local/cache-helper cat /tmp/dst/environment.sh)

BASE_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins | md5sum)
RUBY_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.ruby-runner | md5sum)
YARN_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.yarn-runner | md5sum)
WEBPACK_BUILDER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-builder | md5sum)
WEBPACK_ASSETS_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-assets | md5sum)
WEBPACK_CACHE_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-cache | md5sum)
WEBPACK_RUNNER_DOCKERFILE_MD5=$(cat Dockerfile.jenkins.webpack-runner | md5sum)

./build/new-jenkins/docker-with-flakey-network-protection.sh pull starlord.inscloudgate.net/jenkins/ruby-passenger:$RUBY

BASE_IMAGE_ID=$(docker images --filter=reference=starlord.inscloudgate.net/jenkins/ruby-passenger:$RUBY --format '{{.ID}}')

BASE_RUNNER_BUILD_ARGS=(
  --build-arg CANVAS_RAILS=${CANVAS_RAILS:-7.0}
  --build-arg POSTGRES_CLIENT="$POSTGRES_CLIENT"
  --build-arg RUBY="$RUBY"
)
WEBPACK_RUNNER_BUILD_ARGS=(
  --build-arg SKIP_SOURCEMAPS="$SKIP_SOURCEMAPS"
  --build-arg RAILS_LOAD_ALL_LOCALES="$RAILS_LOAD_ALL_LOCALES"
  --build-arg CRYSTALBALL_MAP="$CRYSTALBALL_MAP"
)
BASE_RUNNER_PARTS=(
  $BASE_IMAGE_ID
  "${BASE_RUNNER_BUILD_ARGS[@]}"
  $BASE_RUNNER_DOCKERFILE_MD5
)
RUBY_RUNNER_PARTS=(
  "${BASE_RUNNER_PARTS[@]}"
  $RUBY_RUNNER_DOCKERFILE_MD5
  $RUBY_RUNNER_MD5
)
YARN_RUNNER_PARTS=(
  "${RUBY_RUNNER_PARTS[@]}"
  $YARN_RUNNER_DOCKERFILE_MD5
  $YARN_RUNNER_MD5
)
WEBPACK_BUILDER_PARTS=(
  "${YARN_RUNNER_PARTS[@]}"
  $WEBPACK_BUILDER_DOCKERFILE_MD5
  $WEBPACK_BUILDER_MD5
)
WEBPACK_RUNNER_PARTS=(
  "${WEBPACK_BUILDER_PARTS[@]}"
  "${WEBPACK_RUNNER_BUILD_ARGS[@]}"
  $WEBPACK_RUNNER_DOCKERFILE_MD5
  $WEBPACK_RUNNER_MD5
  $WEBPACK_RUNNER_DEPENDENCIES_MD5
  $WEBPACK_RUNNER_VENDOR_MD5
)
WEBPACK_ASSETS_PARTS=(
  "${WEBPACK_RUNNER_PARTS[@]}"
  $WEBPACK_ASSETS_DOCKERFILE_MD5
)

# If any of these SHAs change - we don't want to use the previously cached webpack assets to prevent the
# cache from using stale dependencies.
WEBPACK_ASSETS_CACHE_ID_PARTS=(
  "${YARN_RUNNER_PARTS[@]}"
  $WEBPACK_RUNNER_DEPENDENCIES_MD5
  $WEBPACK_RUNNER_DOCKERFILE_MD5
  $WEBPACK_BUILDER_DOCKERFILE_MD5
  $WEBPACK_ASSETS_DOCKERFILE_MD5
)
WEBPACK_ASSETS_CACHE_ID=$(compute_hash ${WEBPACK_ASSETS_CACHE_ID_PARTS[@]})

WEBPACK_CACHE_ID_PARTS=(
  "${YARN_RUNNER_PARTS[@]}"
  $WEBPACK_RUNNER_DEPENDENCIES_MD5
  $WEBPACK_RUNNER_DOCKERFILE_MD5
  $WEBPACK_BUILDER_DOCKERFILE_MD5
  $WEBPACK_CACHE_DOCKERFILE_MD5
  $CACHE_VERSION
)
WEBPACK_CACHE_ID=$(compute_hash ${WEBPACK_CACHE_ID_PARTS[@]})

declare -A BASE_RUNNER_TAGS; compute_tags "BASE_RUNNER_TAGS" $BASE_RUNNER_PREFIX ${BASE_RUNNER_PARTS[@]}
declare -A RUBY_RUNNER_TAGS; compute_tags "RUBY_RUNNER_TAGS" $RUBY_RUNNER_PREFIX ${RUBY_RUNNER_PARTS[@]}
declare -A YARN_RUNNER_TAGS; compute_tags "YARN_RUNNER_TAGS" $YARN_RUNNER_PREFIX ${YARN_RUNNER_PARTS[@]}
declare -A WEBPACK_BUILDER_TAGS; compute_tags "WEBPACK_BUILDER_TAGS" $WEBPACK_BUILDER_PREFIX ${WEBPACK_BUILDER_PARTS[@]}
declare -A WEBPACK_ASSETS_TAGS; compute_tags "WEBPACK_ASSETS_TAGS" $WEBPACK_ASSETS_PREFIX ${WEBPACK_ASSETS_PARTS[@]}

# Patchsets don't currently save their own webpack cache - so if we are reusing the patchset webpack-assets
# image, then we should also make sure the previously built fuzzy image is at least reusable.
if [[ "$WRITE_BUILD_CACHE" == "1" ]]; then
  ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_CACHE_FUZZY_SAVE_TAG || true

  if ! image_label_eq $WEBPACK_CACHE_FUZZY_SAVE_TAG "WEBPACK_CACHE_ID" $WEBPACK_CACHE_ID; then
    export FORCE_BUILD_WEBPACK=1
  fi
fi

WEBPACK_ASSETS_SELECTED_TAG=""; pull_first_tag "WEBPACK_ASSETS_SELECTED_TAG" ${WEBPACK_ASSETS_TAGS[LOAD_TAG]} ${WEBPACK_ASSETS_TAGS[LOAD_FALLBACK_TAG]}

if [[ -z "${WEBPACK_ASSETS_SELECTED_TAG}" || "${FORCE_BUILD_WEBPACK-0}" == "1" ]]; then
  WEBPACK_BUILDER_SELECTED_TAG=""; pull_first_tag "WEBPACK_BUILDER_SELECTED_TAG" ${WEBPACK_BUILDER_TAGS[LOAD_TAG]} ${WEBPACK_BUILDER_TAGS[LOAD_FALLBACK_TAG]}

  if [ -z "${WEBPACK_BUILDER_SELECTED_TAG}" ]; then
    YARN_RUNNER_SELECTED_TAG=""; pull_first_tag "YARN_RUNNER_SELECTED_TAG" ${YARN_RUNNER_TAGS[LOAD_TAG]} ${YARN_RUNNER_TAGS[LOAD_FALLBACK_TAG]}

    if [ -z "${YARN_RUNNER_SELECTED_TAG}" ]; then
      RUBY_RUNNER_SELECTED_TAG=""; pull_first_tag "RUBY_RUNNER_SELECTED_TAG" ${RUBY_RUNNER_TAGS[LOAD_TAG]} ${RUBY_RUNNER_TAGS[LOAD_FALLBACK_TAG]}

      if [ -z "${RUBY_RUNNER_SELECTED_TAG}" ]; then
        BASE_RUNNER_SELECTED_TAG=""; pull_first_tag "BASE_RUNNER_SELECTED_TAG" ${BASE_RUNNER_TAGS[LOAD_TAG]} ${BASE_RUNNER_TAGS[LOAD_FALLBACK_TAG]}

        if [ -z "${BASE_RUNNER_SELECTED_TAG}" ]; then
          docker build \
            "${BASE_RUNNER_BUILD_ARGS[@]}" \
            --tag "${BASE_RUNNER_TAGS[SAVE_TAG]}" \
            - < Dockerfile.jenkins

          BASE_RUNNER_SELECTED_TAG=${BASE_RUNNER_TAGS[SAVE_TAG]}

          add_log "built ${BASE_RUNNER_SELECTED_TAG}"
        fi

        tag_many $BASE_RUNNER_SELECTED_TAG local/base-runner ${BASE_RUNNER_TAGS[SAVE_TAG]}

        docker build \
          --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
          --tag "${RUBY_RUNNER_TAGS[SAVE_TAG]}" \
          - < Dockerfile.jenkins.ruby-runner

        RUBY_RUNNER_SELECTED_TAG=${RUBY_RUNNER_TAGS[SAVE_TAG]}

        add_log "built ${RUBY_RUNNER_SELECTED_TAG}"
      else
        BASE_RUNNER_SELECTED_TAG=$(docker inspect $RUBY_RUNNER_SELECTED_TAG --format '{{ .Config.Labels.BASE_RUNNER_SELECTED_TAG }}')
      fi

      tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}

      docker build \
        --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
        --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
        --tag "${YARN_RUNNER_TAGS[SAVE_TAG]}" \
        - < Dockerfile.jenkins.yarn-runner

      YARN_RUNNER_SELECTED_TAG=${YARN_RUNNER_TAGS[SAVE_TAG]}

      add_log "built ${YARN_RUNNER_SELECTED_TAG}"
    else
      BASE_RUNNER_SELECTED_TAG=$(docker inspect $YARN_RUNNER_SELECTED_TAG --format '{{ .Config.Labels.BASE_RUNNER_SELECTED_TAG }}')
      RUBY_RUNNER_SELECTED_TAG=$(docker inspect $YARN_RUNNER_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')

      ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $RUBY_RUNNER_SELECTED_TAG
      tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}
    fi

    tag_many $YARN_RUNNER_SELECTED_TAG local/yarn-runner ${YARN_RUNNER_TAGS[SAVE_TAG]}

    docker build \
      --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
      --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
      --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
      --tag "${WEBPACK_BUILDER_TAGS[SAVE_TAG]}" \
      - < Dockerfile.jenkins.webpack-builder

    WEBPACK_BUILDER_SELECTED_TAG=${WEBPACK_BUILDER_TAGS[SAVE_TAG]}

    add_log "built ${WEBPACK_BUILDER_SELECTED_TAG}"
  else
    BASE_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_BUILDER_SELECTED_TAG --format '{{ .Config.Labels.BASE_RUNNER_SELECTED_TAG }}')
    RUBY_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_BUILDER_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')
    YARN_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_BUILDER_SELECTED_TAG --format '{{ .Config.Labels.YARN_RUNNER_SELECTED_TAG }}')

    # If we're here, that means webpack-builder was re-used, so we need to ensure
    # that the ancestor images are correctly tagged.
    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $YARN_RUNNER_SELECTED_TAG
    tag_many $YARN_RUNNER_SELECTED_TAG local/yarn-runner ${YARN_RUNNER_TAGS[SAVE_TAG]}

    ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $RUBY_RUNNER_SELECTED_TAG
    tag_many $RUBY_RUNNER_SELECTED_TAG local/ruby-runner ${RUBY_RUNNER_TAGS[SAVE_TAG]}
  fi

  tag_many $WEBPACK_BUILDER_SELECTED_TAG local/webpack-builder ${WEBPACK_BUILDER_TAGS[SAVE_TAG]} ${WEBPACK_BUILDER_TAGS[UNIQUE_TAG]-} ${WEBPACK_BUILDER_FUZZY_SAVE_TAG-}

  [[ ! -z "${WEBPACK_ASSETS_FUZZY_LOAD_TAG-}" && "$READ_BUILD_CACHE" == "1" ]] && load_image_if_label_eq \
    $WEBPACK_ASSETS_FUZZY_LOAD_TAG \
    "WEBPACK_ASSETS_CACHE_ID" \
    $WEBPACK_ASSETS_CACHE_ID \
    local/webpack-assets-previous \
  || tag_many starlord.inscloudgate.net/jenkins/core:focal local/webpack-assets-previous

  [[ ! -z "${WEBPACK_CACHE_FUZZY_LOAD_TAG-}" && "$READ_BUILD_CACHE" == "1" ]] && load_image_if_label_eq \
    $WEBPACK_CACHE_FUZZY_LOAD_TAG \
    "WEBPACK_CACHE_ID" \
    $WEBPACK_CACHE_ID \
    local/webpack-cache-previous \
  && export USE_BUILD_CACHE=1 \
  || tag_many starlord.inscloudgate.net/jenkins/core:focal local/webpack-cache-previous

  # *_BUILD_CACHE are special variables and do not need to be included in the image cache hash
  # because it shouldn't produce any compiled asset changes
  docker build \
    "${WEBPACK_RUNNER_BUILD_ARGS[@]}" \
    --build-arg USE_BUILD_CACHE="${USE_BUILD_CACHE-0}" \
    --build-arg WRITE_BUILD_CACHE="${WRITE_BUILD_CACHE-0}" \
    --no-cache \
    --tag local/webpack-runner \
    - < Dockerfile.jenkins.webpack-runner

  docker build \
    --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
    --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
    --label "WEBPACK_ASSETS_CACHE_ID=$WEBPACK_ASSETS_CACHE_ID" \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
    --no-cache \
    --tag "${WEBPACK_ASSETS_TAGS[SAVE_TAG]}" \
    - < Dockerfile.jenkins.webpack-assets

  if [[ "$WRITE_BUILD_CACHE" == "1" ]]; then
    docker build \
      --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
      --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
      --label "WEBPACK_CACHE_ID=$WEBPACK_CACHE_ID" \
      --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
      --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
      --no-cache \
      --tag "${WEBPACK_CACHE_FUZZY_SAVE_TAG-}" \
      - < Dockerfile.jenkins.webpack-cache
  fi

  WEBPACK_ASSETS_SELECTED_TAG=${WEBPACK_ASSETS_TAGS[SAVE_TAG]}

  add_log "built ${WEBPACK_ASSETS_SELECTED_TAG}"
else
  BASE_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_ASSETS_SELECTED_TAG --format '{{ .Config.Labels.BASE_RUNNER_SELECTED_TAG }}')
  RUBY_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_ASSETS_SELECTED_TAG --format '{{ .Config.Labels.RUBY_RUNNER_SELECTED_TAG }}')
  YARN_RUNNER_SELECTED_TAG=$(docker inspect $WEBPACK_ASSETS_SELECTED_TAG --format '{{ .Config.Labels.YARN_RUNNER_SELECTED_TAG }}')
  WEBPACK_BUILDER_SELECTED_TAG=$(docker inspect $WEBPACK_ASSETS_SELECTED_TAG --format '{{ .Config.Labels.WEBPACK_BUILDER_SELECTED_TAG }}')

  [ "$RUBY_RUNNER_SELECTED_TAG" != "${RUBY_RUNNER_TAGS[SAVE_TAG]}" ] && tag_remote_async "RUBY_RUNNER_TAG_REMOTE_SAVE_PID" $RUBY_RUNNER_SELECTED_TAG ${RUBY_RUNNER_TAGS[SAVE_TAG]}
  [ "$YARN_RUNNER_SELECTED_TAG" != "${YARN_RUNNER_TAGS[SAVE_TAG]}" ] && tag_remote_async "YARN_RUNNER_TAG_REMOTE_SAVE_PID" $YARN_RUNNER_SELECTED_TAG ${YARN_RUNNER_TAGS[SAVE_TAG]}
  [ "$WEBPACK_BUILDER_SELECTED_TAG" != "${WEBPACK_BUILDER_TAGS[SAVE_TAG]}" ] && tag_remote_async "WEBPACK_BUILDER_TAG_REMOTE_SAVE_PID" $WEBPACK_BUILDER_SELECTED_TAG ${WEBPACK_BUILDER_TAGS[SAVE_TAG]}

  [ ! -z "${CACHE_UNIQUE_SCOPE-}" ] && tag_remote_async "WEBPACK_BUILDER_TAG_REMOTE_UNIQUE_PID" $WEBPACK_BUILDER_SELECTED_TAG ${WEBPACK_BUILDER_TAGS[UNIQUE_TAG]}
  [ ! -z "${CACHE_UNIQUE_SCOPE-}" ] && tag_remote_async "WEBPACK_ASSETS_TAG_REMOTE_UNIQUE_PID" $WEBPACK_ASSETS_SELECTED_TAG ${WEBPACK_ASSETS_TAGS[UNIQUE_TAG]}
fi

tag_many $WEBPACK_ASSETS_SELECTED_TAG local/webpack-assets ${WEBPACK_ASSETS_TAGS[SAVE_TAG]} ${WEBPACK_ASSETS_TAGS[UNIQUE_TAG]-} ${WEBPACK_ASSETS_FUZZY_SAVE_TAG-}

# Build Final Image
if [ -n "${1:-}" ]; then
  docker build \
    --build-arg COMPILE_ADDITIONAL_ASSETS="$COMPILE_ADDITIONAL_ASSETS" \
    --file Dockerfile.jenkins.final \
    --label "BASE_RUNNER_SELECTED_TAG=$BASE_RUNNER_SELECTED_TAG" \
    --label "RUBY_RUNNER_SELECTED_TAG=$RUBY_RUNNER_SELECTED_TAG" \
    --label "WEBPACK_BUILDER_SELECTED_TAG=$WEBPACK_BUILDER_SELECTED_TAG" \
    --label "WEBPACK_ASSETS_SELECTED_TAG=$WEBPACK_ASSETS_SELECTED_TAG" \
    --label "YARN_RUNNER_SELECTED_TAG=$YARN_RUNNER_SELECTED_TAG" \
    --tag "$1" \
    "$WORKSPACE"

  add_log "built $1"
fi
