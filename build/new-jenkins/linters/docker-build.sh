#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

WORKSPACE=${WORKSPACE:-$(pwd)}

./build/new-jenkins/docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker tag $WEBPACK_BUILDER_IMAGE local/webpack-builder

docker build \
  --file Dockerfile.jenkins.linters-runner \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "local/linters-runner" \
  "$WORKSPACE"

# The .git directory is ignored by .dockerignore, so we work around this by
# mounting the .git directory itself as the build context and copying it in.
docker build \
  --build-arg DST_WORKDIR="$DOCKER_WORKDIR/.git" \
  --file Dockerfile.jenkins.linters-final \
  --label "WEBPACK_BUILDER_IMAGE=$WEBPACK_BUILDER_IMAGE" \
  --tag "$1" \
  "$LOCAL_WORKDIR/.git"
