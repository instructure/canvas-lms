#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

export CACHE_VERSION="2020-12-15.1"

echo "" > tmp/docker-build.log

function add_log {
  echo "$1" >> tmp/docker-build.log
}

function compute_tags {
  local -n tags=$1; shift
  local cachePrefix=$1; shift
  local cacheId=$(echo "$@" | md5sum | cut -d' ' -f1)
  local cacheSalt=$(echo "$CACHE_VERSION" | md5sum | cut -c1-8)

  tags[LOAD_TAG]="$cachePrefix:$CACHE_LOAD_SCOPE-$cacheSalt-$cacheId"
  tags[LOAD_FALLBACK_TAG]="$cachePrefix:$CACHE_LOAD_FALLBACK_SCOPE-$cacheSalt-$cacheId"
  tags[SAVE_TAG]="$cachePrefix:$CACHE_SAVE_SCOPE-$cacheSalt-$cacheId"
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
