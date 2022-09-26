#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

git show --pretty="" --name-only HEAD^..HEAD > /tmp/git_changes.txt

echo "" > /tmp/webpack_changes.txt
docker run local/cache-helper tar tf /tmp/dst/yarn-runner.tar >> /tmp/webpack_changes.txt
docker run local/cache-helper tar tf /tmp/dst/webpack-builder.tar >> /tmp/webpack_changes.txt
docker run local/cache-helper tar tf /tmp/dst/js.tar >> /tmp/webpack_changes.txt

echo "Git Changes: $(cat /tmp/git_changes.txt | head -n 10)"
echo "Webpack Changes: $(cat /tmp/webpack_changes.txt | head -n 10)"

cat /tmp/git_changes.txt | while read line; do echo "${DOCKER_WORKDIR/\/usr\/src\/app\/}${line}"; done | sort | uniq > /tmp/git_changes_sorted.txt
cat /tmp/webpack_changes.txt | sort | uniq > /tmp/webpack_changes_sorted.txt

if [[ $(comm -12 /tmp/git_changes_sorted.txt /tmp/webpack_changes_sorted.txt) == "" ]]; then
  exit 1
else
  exit 0
fi
