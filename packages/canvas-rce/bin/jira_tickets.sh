#!/bin/sh

if [ "${1}" == "" ]; then
  echo "release number not provided, pulling from the latest"
  release_ver=v`npm view | grep "dist-tags" | sed "s/.*latest: '\([0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}\)'.*/\1/"`
else
  release_ver=${1}
fi

echo "using release version: ${release_ver}"

for f in `git cherry -v "${release_ver}" | sed "s/+ \([0-9a-f]\{40\}\).*/\1/"` ; do
  git show -s --format=%B ${f} | egrep "(fixes|refs|closes) [A-Za-z]{4}-[0-9]{5,6}"
done
