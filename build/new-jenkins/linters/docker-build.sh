#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker tag $WEBPACK_BUILDER_IMAGE local/webpack-builder

# The steps taken by this image require git support
cp .dockerignore Dockerfile.jenkins.linters.dockerignore
echo "!.git" >> Dockerfile.jenkins.linters.dockerignore
echo "!gems/plugins/*/.git" >> Dockerfile.jenkins.linters.dockerignore

DOCKER_BUILDKIT=1 docker build \
  --file Dockerfile.jenkins.linters \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$WORKSPACE"
