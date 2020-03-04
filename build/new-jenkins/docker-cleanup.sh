#!/bin/bash

function show_usage_and_exit {
    echo ">> a tool for cleaning up local docker daemon

usage:
$(basename "$0") [--allow-failure] [--all] [--whitelist <image> ...]
where:
    --allow-failure   allows the docker commands to fail
    --all             clean everything from docker
    --whitelist       add an image to be whitelisted
    --help            prints this
"
    exit 1
}

set -e

whitelist=()
whitelist+=('instructure/ruby-passenger')
whitelist+=('starlord.inscloudgate.net/jenkins/canvas-lms:master')
whitelist+=('starlord.inscloudgate.net/jenkins/dynamodb-local')
whitelist+=('starlord.inscloudgate.net/jenkins/redis')
whitelist+=('starlord.inscloudgate.net/jenkins/cassandra')
whitelist+=('starlord.inscloudgate.net/jenkins/postgres')

ALLOW_FAILURE="0"
CLEAN_ALL="0"

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --allow-failure)
    ALLOW_FAILURE="1"
    shift
    ;;
    --all)
    CLEAN_ALL="1"
    shift
    ;;
    --whitelist)
    whitelist+=("$2")
    shift
    shift
    ;;
    --help)
    show_usage_and_exit
    ;;
    *)
    echo "unknown option: $key"
    show_usage_and_exit
    ;;
esac
done

# this is here so we dont get a bunch of junk to get printed when parsing args
set -x -o errexit -o errtrace -o nounset -o pipefail

if [[ $ALLOW_FAILURE == "1" ]]; then
  echo "WARNING: allowing failure during cleanup"
  set +e
fi

function docker_env_status {
  echo "============================================"
  echo "running docker images"
  docker ps -a
  echo "images locally"
  docker images -a
  echo "volumes left over"
  docker volume ls
  echo "networks left over"
  docker network ls
  echo "HD space info"
  docker system df
  echo "============================================"
}

echo "== status before clean"
docker_env_status

# kill all running containers
containers="$(docker ps --quiet)"
if [[ $containers != "" ]]; then
  docker kill $containers
fi

if [[ $CLEAN_ALL == "1" ]]; then
  # delete all the things!
  docker system prune --all --force --volumes
else
  # delete most the things!
  dangling_image_ids=$(docker images --filter "dangling=true" -q --no-trunc)
  if [[ $dangling_image_ids != "" ]]; then
    docker rmi --force $dangling_image_ids
  fi
  regex=()
  regex+=(--regexp="REPOSITORY:TAG")
  for allowed in "${whitelist[@]}"; do
    regex+=("--regexp=$allowed")
  done
  image_ids=$(docker images --all | awk '{ print $1 ":" $2 " " $3 }' | grep --fixed-strings --invert-match ${regex[@]} | awk '{ print $2 }' || echo '')
  if [[ $image_ids != "" ]]; then
    docker rmi --force $image_ids
  fi
  docker system prune --force --volumes
fi

echo "== status after clean"
docker_env_status
