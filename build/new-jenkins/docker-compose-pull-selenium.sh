#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

docker pull $REGISTRY_BASE/selenium-chrome:3.141.59-xenon || \
  (docker build -t $REGISTRY_BASE/selenium-chrome:3.141.59-xenon docker-compose/selenium-chrome && \
  docker push $REGISTRY_BASE/selenium-chrome:3.141.59-xenon)
