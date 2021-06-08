#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

cat <<EOF | docker run --interactive $DOCKER_INPUTS --volume $GERGICH_VOLUME:/home/docker/gergich $LINTERS_RUNNER_IMAGE /bin/bash -
set -ex
export GERGICH_REVIEW_LABEL="Lint-Review"
gergich status

if [[ "\$GERGICH_PUBLISH" == "1" ]]; then
  GERGICH_GIT_PATH=".." gergich publish
fi
EOF
