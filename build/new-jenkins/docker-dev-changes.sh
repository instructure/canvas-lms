#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }

fileArr=(
  '^docker-compose/'
  '^build/common_docker_build_steps.sh'
  '^script/canvas_update'
  '^docker-compose.yml'
  '^Dockerfile$'
  '^lib/tasks/'
  'Jenkinsfile.docker-smoke'
)

files=$(join_by '|' "${fileArr[@]}")

changed="$(git show --pretty="" --name-only HEAD^..HEAD | grep -E "${files}")"

[[ -n "$changed" ]]; exit $?
