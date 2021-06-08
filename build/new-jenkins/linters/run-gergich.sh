#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

DOCKER_INPUTS=$DOCKER_INPUTS GERGICH_VOLUME=$GERGICH_VOLUME ./build/new-jenkins/linters/run-gergich-webpack.sh &
WEBPACK_BUILD_PID=$!

DOCKER_INPUTS=$DOCKER_INPUTS GERGICH_VOLUME=$GERGICH_VOLUME ./build/new-jenkins/linters/run-gergich-linters.sh &
LINTER_PID=$!

if [ "$GERRIT_PROJECT" == "canvas-lms" ] && git diff --name-only HEAD~1..HEAD | grep -E "package.json|yarn.lock"; then
  DOCKER_INPUTS=$DOCKER_INPUTS GERGICH_VOLUME=$GERGICH_VOLUME ./build/new-jenkins/linters/run-gergich-yarn.sh &
  YARN_LOCK_PID=$!
fi

wait $WEBPACK_BUILD_PID
wait $LINTER_PID
[ ! -z "${YARN_LOCK_PID-}" ] && wait $YARN_LOCK_PID

exit 0
