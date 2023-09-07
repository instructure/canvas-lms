#!/bin/bash

set -ex

for TEST_FILE in Gemfile.*.lock; do
  echo "checking $TEST_FILE with snyk"

  npx snyk auth $SNYK_TOKEN
  npx snyk test --severity-threshold=low --file=$TEST_FILE --org=canvas-lms --project-name=canvas-lms:ruby --packageManager=rubygems || true
  npx snyk monitor --severity-threshold=low --file=$TEST_FILE --org=canvas-lms --project-name=canvas-lms:ruby --packageManager=rubygems
done

if [[ -z "$TEST_FILE" ]]; then
  echo "could not find any supported file to check"
  exit 1
fi
