#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

tests="$(git show --pretty="" --name-only HEAD^..HEAD | grep "_spec.rb")"

[[ -n "$tests" ]]; exit $?
