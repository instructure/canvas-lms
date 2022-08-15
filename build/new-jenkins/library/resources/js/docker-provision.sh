#!/usr/bin/env bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

# We don't need these images right away, but start pulling them while we're building the final JS runner image.
./docker-with-flakey-network-protection.sh pull $SELENIUM_NODE_IMAGE &
./docker-with-flakey-network-protection.sh pull $SELENIUM_HUB_IMAGE &

./docker-with-flakey-network-protection.sh pull $KARMA_RUNNER_IMAGE
WEBPACK_BUILDER_IMAGE=$(docker image inspect -f "{{.Config.Labels.WEBPACK_BUILDER_IMAGE}}" $KARMA_RUNNER_IMAGE)

./docker-with-flakey-network-protection.sh pull $WEBPACK_BUILDER_IMAGE

docker build --tag local/karma-runner - <<EOF
FROM $WEBPACK_BUILDER_IMAGE
COPY --from=$KARMA_RUNNER_IMAGE --chown=docker:docker /tmp/dst/. /usr/src/app
EOF

wait
