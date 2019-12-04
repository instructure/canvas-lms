#!/bin/bash

set -e
printenv | sort

docker run --volume $WORKSPACE/containertmp:/tmp/ \
  --volume $WORKSPACE/.git:/usr/src/app/.git \
  --env GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION \
  --env GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID \
  --env GERRIT_PROJECT=$GERRIT_PROJECT \
  --env GERRIT_BRANCH=$GERRIT_BRANCH \
  $PATCHSET_TAG gergich citest
