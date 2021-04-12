#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker tag $WEBPACK_BUILDER_IMAGE local/webpack-builder

docker build \
  --file Dockerfile.jenkins.linters-runner \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$WORKSPACE"
