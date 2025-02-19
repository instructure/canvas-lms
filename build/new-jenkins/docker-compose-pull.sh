#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# Pull all docker images that are used for rspec / selenium in advance of
# running docker compose up for protection against flakey network requests.
# Always pull all images, even if the rspec job does not use them, so that
# the image cache is completely fulfilled and subsequent builds don't need
# to load them. This helps our build times to remain more consistent.

REGISTRY_BASE=starlord.inscloudgate.net/jenkins
ECR_BASE=948781806214.dkr.ecr.us-east-1.amazonaws.com/docker.io

DOCKER_IMAGES=(
  $PATCHSET_TAG
  $DYNAMODB_IMAGE_TAG
  $POSTGRES_IMAGE_TAG
  $REGISTRY_BASE/canvas-rce-api
  $REGISTRY_BASE/redis:alpine
  $ECR_BASE/selenium/node-chromium:"${CHROME_VERSION:-126.0-20240621}"
  $ECR_BASE/selenium/hub:"${HUB_VERSION:-4.22.0}"
)

echo "${DOCKER_IMAGES[@]}" | xargs -P0 -n1 ./build/new-jenkins/docker-with-flakey-network-protection.sh pull &
wait

# When this build finishes, the docker clean-up script will remove the $PATCHSET_TAG
# because it is unlikely that another build that runs on the node will need it, saving
# disk space. The dependency image(s) will not be cleared however, so tag them to avoid
# future builds on this node from downloading the layers again.
WEBPACK_ASSETS_SELECTED_TAG=$(docker image inspect -f "{{.Config.Labels.WEBPACK_ASSETS_SELECTED_TAG}}" $PATCHSET_TAG)
./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_ASSETS_SELECTED_TAG
