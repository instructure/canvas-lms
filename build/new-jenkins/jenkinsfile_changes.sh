#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }

fileArr=(
  '^Jenkinsfile$'
  '^Jenkinsfile.contract-tests$'
  '^Jenkinsfile.docker-smoke$'
  '^Jenkinsfile.js$'
  '^Jenkinsfile.selenium.flakey_spec_catcher$'
  '^Jenkinsfile.vendored-gems$'
)

files=$(join_by '|' "${fileArr[@]}")

changed="$(git show --pretty="" --name-only HEAD^..HEAD | grep -E "${files}")"

[[ -n "$changed" ]]; exit $?
