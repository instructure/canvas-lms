#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

git show --pretty="" --name-only HEAD^..HEAD > /tmp/git_changes.txt
cat /tmp/git_changes.txt | sort | uniq > /tmp/git_changes_sorted.txt

echo "" > /tmp/webpack_changes.txt
docker run local/cache-helper-collect-yarn sh -c "cd ${DOCKER_WORKDIR/\/usr\/src\/app/\/tmp\/dst} && find . -type f | sed 's|^./||'" >> /tmp/webpack_changes.txt
docker run local/cache-helper-collect-packages sh -c "cd ${DOCKER_WORKDIR/\/usr\/src\/app/\/tmp\/dst} && find . -type f | sed 's|^./||'" >> /tmp/webpack_changes.txt
docker run local/cache-helper-collect-js sh -c "cd ${DOCKER_WORKDIR/\/usr\/src\/app/\/tmp\/dst} && find . -type f | sed 's|^./||'" >> /tmp/webpack_changes.txt

cat /tmp/webpack_changes.txt | sort | uniq > /tmp/webpack_changes_sorted.txt

if [[ $(comm -12 /tmp/git_changes_sorted.txt /tmp/webpack_changes_sorted.txt) == "" ]]; then
  exit 1
else
  exit 0
fi
