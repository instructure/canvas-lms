#!/bin/bash

set -ex

SNYK_PINNED_VERSION="1.1100.0"

for TEST_FILE in Gemfile.*.lock; do
  echo "checking $TEST_FILE with snyk"

  npx snyk@$SNYK_PINNED_VERSION auth $SNYK_TOKEN
  npx snyk@$SNYK_PINNED_VERSION test --severity-threshold=low --file=$TEST_FILE --org=instructure --project-name=canvas-lms:ruby --packageManager=rubygems || true
  npx snyk@$SNYK_PINNED_VERSION monitor --severity-threshold=low --file=$TEST_FILE --org=instructure --project-name=canvas-lms:ruby --packageManager=rubygems
done

if [[ -z "$TEST_FILE" ]]; then
  echo "could not find any supported file to check"
  exit 1
fi
