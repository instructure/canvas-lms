#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":"$(pwd)" \
  -w "$(pwd)" \
  wagoodman/dive:latest \
  "$IMAGE" --ci \
    --lowestEfficiency 0.80 \
    --highestWastedBytes 1GB \
    --highestUserWastedPercent 0.20
