#!/bin/bash

# pull docker images (or build them if missing)
REGISTRY_BASE=starlord.inscloudgate.net/jenkins

docker pull $REGISTRY_BASE/selenium-chrome:3.141.59-selenium || \
  (docker build -t $REGISTRY_BASE/selenium-chrome:3.141.59-selenium docker-compose/selenium-chrome && \
  docker push $REGISTRY_BASE/selenium-chrome:3.141.59-selenium)
