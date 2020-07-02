#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION" || \
  (docker build -t $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION" --build-arg SELENIUM_VERSION="$SELENIUM_VERSION" build/docker-compose/selenium-chrome && \
  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $REGISTRY_BASE/selenium-chrome:"$SELENIUM_VERSION")
