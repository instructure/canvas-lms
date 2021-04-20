#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

git fetch --depth 1 --force --no-tags origin "$GERRIT_BRANCH":"$GERRIT_BRANCH"

docker volume create $GERGICH_VOLUME

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

cat <<EOF | docker run --interactive $DOCKER_INPUTS --volume $GERGICH_VOLUME:/home/docker/gergich local/gergich /bin/bash -
set -ex
export GERGICH_REVIEW_LABEL="Lint-Review"
gergich status

if [[ "\$GERGICH_PUBLISH" == "1" ]]; then
  GERGICH_GIT_PATH=".." gergich publish
fi
EOF

[[ "$FORCE_FAILURE" == "true" ]] && exit 1

exit 0
