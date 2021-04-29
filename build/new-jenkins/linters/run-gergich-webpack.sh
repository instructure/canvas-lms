#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

cat <<EOF | docker run \
  $DOCKER_INPUTS \
  --interactive \
  --volume $GERGICH_VOLUME:/home/docker/gergich \
  local/gergich /bin/bash -
set -ex
export COMPILE_ASSETS_NPM_INSTALL=0
export JS_BUILD_NO_FALLBACK=1
gergich capture custom:./build/gergich/compile_assets:Gergich::CompileAssets 'rake canvas:compile_assets'
yarn lint:browser-code
gergich status
echo "WEBPACK_BUILD OK!"
EOF
