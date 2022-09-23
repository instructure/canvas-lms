#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

git show --pretty="" --name-only HEAD^..HEAD > /tmp/git_changes.txt
cat /tmp/git_changes.txt | sort | uniq > /tmp/git_changes_sorted.txt

echo "" > /tmp/webpack_changes.txt
docker run local/cache-helper sh -c "tar tf /tmp/dst/yarn-runner.tar | grep '${DOCKER_WORKDIR/\/usr\/src\/app\/}'" >> /tmp/webpack_changes.txt
docker run local/cache-helper sh -c "tar tf /tmp/dst/webpack-builder.tar | grep '${DOCKER_WORKDIR/\/usr\/src\/app\/}'" >> /tmp/webpack_changes.txt
docker run local/cache-helper sh -c "tar tf /tmp/dst/js.tar | grep '${DOCKER_WORKDIR/\/usr\/src\/app\/}'" >> /tmp/webpack_changes.txt

cat /tmp/webpack_changes.txt | sort | uniq > /tmp/webpack_changes_sorted.txt

if [[ $(comm -12 /tmp/git_changes_sorted.txt /tmp/webpack_changes_sorted.txt) == "" ]]; then
  exit 1
else
  exit 0
fi
