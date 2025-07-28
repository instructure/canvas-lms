#!/bin/bash

set -e
export NODE_OPTIONS="--max-old-space-size=8192"

exit_status=0

if [ "${SKIP_ESLINT-}" != "true" ]; then
  files=$(git diff --name-only --diff-filter=d HEAD^ -- '*.js' '*.jsx' '*.ts' '*.tsx')
  if [ -n "$files" ]; then
    echo "Running ESLint..."
    yarn run lint $files --quiet || { echo "ESLint check failed"; exit_status=1; }
  else
    echo "No changed JS/TS files to run ESLint on..."
  fi
else
  echo "Skipping ESLint..."
fi

exit $exit_status