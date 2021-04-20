#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

git fetch --depth 1 --force --no-tags origin "$GERRIT_BRANCH":"$GERRIT_BRANCH"

inputs=()
inputs+=("--volume $(pwd)/.git:/usr/src/app/.git")
inputs+=("--env GERGICH_DB_PATH=/home/docker/gergich")
inputs+=("--env GERGICH_PUBLISH=$GERGICH_PUBLISH")
inputs+=("--env GERGICH_KEY=$GERGICH_KEY")
inputs+=("--env GERRIT_HOST=$GERRIT_HOST")
inputs+=("--env GERRIT_PROJECT=$GERRIT_PROJECT")
inputs+=("--env GERRIT_BRANCH=$GERRIT_BRANCH")
inputs+=("--env GERRIT_EVENT_ACCOUNT_EMAIL=$GERRIT_EVENT_ACCOUNT_EMAIL")
inputs+=("--env GERRIT_PATCHSET_NUMBER=$GERRIT_PATCHSET_NUMBER")
inputs+=("--env GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION")
inputs+=("--env GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID")
inputs+=("--env GERRIT_CHANGE_NUMBER=$GERRIT_CHANGE_NUMBER")

if [ "$GERRIT_PROJECT" != "canvas-lms" ]; then
  inputs+=("--volume $(pwd)/gems/plugins/$GERRIT_PROJECT/.git:/usr/src/app/gems/plugins/$GERRIT_PROJECT/.git")
  inputs+=("--env GERGICH_GIT_PATH=/usr/src/app/gems/plugins/$GERRIT_PROJECT")
fi

# the GERRIT_REFSPEC is required for the commit message to actually
# send things to gergich
inputs+=("--env GERRIT_REFSPEC=$GERRIT_REFSPEC")

# Sometimes Docker doesn't clean up the volume completely and
# errors when trying to create the backing folder. Make it
# unique to avoid this.
GERGICH_VOLUME="gergich-results-$(date +%s)"
docker volume create $GERGICH_VOLUME

DOCKER_INPUTS=${inputs[@]} \
  GERGICH_VOLUME=$GERGICH_VOLUME \
  ./build/new-jenkins/linters/run-gergich-webpack.sh &
WEBPACK_BUILD_PID=$!

DOCKER_INPUTS=${inputs[@]} \
  GERGICH_VOLUME=$GERGICH_VOLUME \
  ./build/new-jenkins/linters/run-gergich-linters.sh &
LINTER_PID=$!

if [ "$GERRIT_PROJECT" == "canvas-lms" ] && git diff --name-only HEAD~1..HEAD | grep -E "package.json|yarn.lock"; then
  DOCKER_INPUTS=${inputs[@]} \
    GERGICH_VOLUME=$GERGICH_VOLUME \
    ./build/new-jenkins/linters/run-gergich-yarn.sh &
  YARN_LOCK_PID=$!
fi

wait $WEBPACK_BUILD_PID
wait $LINTER_PID
[ ! -z "${YARN_LOCK_PID-}" ] && wait $YARN_LOCK_PID

cat <<EOF | docker run --interactive ${inputs[@]} --volume $GERGICH_VOLUME:/home/docker/gergich local/gergich /bin/bash -
set -ex
export GERGICH_REVIEW_LABEL="Lint-Review"
gergich status

if [[ "\$GERGICH_PUBLISH" == "1" ]]; then
  GERGICH_GIT_PATH=".." gergich publish
fi
EOF

[[ "$FORCE_FAILURE" == "true" ]] && exit 1

exit 0
