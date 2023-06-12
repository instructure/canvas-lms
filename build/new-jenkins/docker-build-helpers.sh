#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

echo "" > tmp/docker-build.log

function add_log {
  echo "$1" >> tmp/docker-build.log
}

function compute_hash {
  echo "$@" | md5sum | cut -d' ' -f1
}

function compute_tags {
  local tags=$1; shift
  local cachePrefix=$1; shift
  local cacheId=$(compute_hash $@)

  compute_tags_from_hash $tags $cachePrefix $cacheId
}

function compute_tags_from_hash {
  local -n tags=$1; shift
  local cachePrefix=$1; shift
  local cacheId=$1; shift
  local cacheSalt=$(echo "$CACHE_VERSION" | md5sum | cut -c1-8)

  [ ! -z "${CACHE_LOAD_SCOPE-}" ] && tags[LOAD_TAG]="$cachePrefix:$CACHE_LOAD_SCOPE-$cacheSalt-$cacheId${CACHE_SUFFIX-}${PLATFORM_SUFFIX-}"
  [ ! -z "${CACHE_LOAD_FALLBACK_SCOPE-}" ] && tags[LOAD_FALLBACK_TAG]="$cachePrefix:$CACHE_LOAD_FALLBACK_SCOPE-$cacheSalt-$cacheId${CACHE_SUFFIX-}${PLATFORM_SUFFIX-}"
  [ ! -z "${CACHE_SAVE_SCOPE-}" ] && tags[SAVE_TAG]="$cachePrefix:$CACHE_SAVE_SCOPE-$cacheSalt-$cacheId${CACHE_SUFFIX-}${PLATFORM_SUFFIX-}"
  [ ! -z "${CACHE_UNIQUE_SCOPE-}" ] && tags[UNIQUE_TAG]="$cachePrefix:$CACHE_UNIQUE_SCOPE${PLATFORM_SUFFIX-}"

  return 0
}

function has_remote_tags {
  local checkTags=$@

  for imageTag in $checkTags; do
    if ! DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect $imageTag; then
      return 1
    fi
  done

  return 0
}

function image_label_eq {
  local imageName=$1; shift
  local labelName=$1; shift
  local expectedValue=$1; shift
  local actualValue=$(docker inspect $imageName --format "{{ .Config.Labels.$labelName }}")

  if [[ "$actualValue" != "$expectedValue" ]]; then
    return 1
  fi

  return 0
}

function load_image_if_label_eq  {
  local imageName=$1; shift
  local labelName=$1; shift
  local expectedValue=$1; shift
  local outputImageName=$1; shift

  ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $imageName

  if ! image_label_eq $imageName $labelName $expectedValue; then
    return 1
  fi

  tag_many $imageName $outputImageName
}

function pull_first_tag {
  local -n selectedTag=$1; shift
  local loadTags=$@

  for imageTag in $loadTags; do
    if ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $imageTag; then
      add_log "using $imageTag"

      selectedTag=$imageTag

      return
    fi
  done
}

function tag_many {
  local srcTag=$1; shift
  local dstTags=$@

  for imageTag in $dstTags; do
    [ "$srcTag" != "$imageTag" ] && [[ "$imageTag" != "local/"* ]] && add_log "alias $imageTag"

    docker tag $srcTag $imageTag
  done
}

function tag_remote_async {
  local -n childPID=$1; shift
  local srcTag=$1; shift
  local dstTag=$1; shift

  ./build/new-jenkins/docker-tag-remote.sh $srcTag $dstTag &
  childPID=$!
}

function wait_for_children {
  for job in $(jobs -p); do
    wait $job
  done
}
