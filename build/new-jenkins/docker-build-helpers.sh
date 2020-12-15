#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

export CACHE_VERSION="2020-12-15"

function compute_tags {
  local -n tags=$1; shift
  local cachePrefix=$1; shift
  local cacheId=$(echo "$@" | md5sum | cut -d' ' -f1)
  local cacheSalt=$(echo "$CACHE_VERSION" | md5sum | cut -c1-8)

  tags[LOAD_TAG]="$cachePrefix:$CACHE_LOAD_SCOPE-$cacheSalt-$cacheId"
  tags[LOAD_FALLBACK_TAG]="$cachePrefix:$CACHE_LOAD_FALLBACK_SCOPE-$cacheSalt-$cacheId"
  tags[SAVE_TAG]="$cachePrefix:$CACHE_SAVE_SCOPE-$cacheSalt-$cacheId"
}

function pull_first_tag {
  local -n selectedTag=$1; shift
  local loadTags=$@

  for imageTag in $loadTags; do
    if ./build/new-jenkins/docker-with-flakey-network-protection.sh pull $imageTag; then
      selectedTag=$imageTag

      return
    fi
  done
}

function tag_many {
  local srcTag=$1; shift
  local dstTags=$@

  for imageTag in $dstTags; do
    docker tag $srcTag $imageTag
  done
}
