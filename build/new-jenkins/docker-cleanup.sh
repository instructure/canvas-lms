#!/bin/bash

function show_usage_and_exit {
    echo ">> a tool for cleaning up local docker daemon

usage:
$(basename "$0") [--allow-failure]
where:
    --allow-failure   allows the docker-compose commands to fail
    --help            prints this
"
    exit 1
}

set -e

ALLOW_FAILURE="0"

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --allow-failure)
    ALLOW_FAILURE="1"
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

if [[ $ALLOW_FAILURE == "1" ]]; then
  echo "WARNING: allowing failure during cleanup"
fi

# this is here so we dont get a bunch of junk to get printed when parsing args
set -x -o errexit -o errtrace -o nounset -o pipefail

# sometimes things don't cleanup so run this a few times
if [[ $ALLOW_FAILURE == "1" ]]; then
  docker-compose stop || true
  docker-compose down --volumes --remove-orphans --rmi all || true
  docker-compose stop || true
  docker-compose down --volumes --remove-orphans --rmi all || true
  docker-compose stop || true
  docker-compose down --volumes --remove-orphans --rmi all || true
else
  docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
  docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
  docker-compose stop && docker-compose down --volumes --remove-orphans --rmi all
fi

# remove all containers
docker rm --force --volumes $(docker ps --all --quiet) || true

# delete all images
docker rmi -f $(docker images --all --quiet) || true

# remove any extra networks (errors saying unable to remove is ok)
docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }') || true

echo "running docker images"
docker ps -a || true
echo "images locally"
docker images -a || true
echo "volumes left over"
docker volume ls || true
echo "networks left over"
docker network ls || true
