#!/bin/bash

set -ex
export GERGICH_REVIEW_LABEL="Lint-Review"
gergich status

if [[ "$GERGICH_PUBLISH" == "1" ]]; then
  GERGICH_GIT_PATH=".." gergich publish
fi
