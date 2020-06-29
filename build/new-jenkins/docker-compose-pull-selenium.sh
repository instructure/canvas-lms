#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

docker pull $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION" || \
  (docker build -t $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION" --build-arg SELENIUM_VERSION="$SELENIUM_VERSION" build/docker-compose/selenium-chrome && \
  docker push $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION")
