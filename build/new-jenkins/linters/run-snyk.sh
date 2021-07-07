#!/bin/bash

set -ex

TEST_FILE=""

if test -f "Gemfile.lock"; then
  TEST_FILE="Gemfile.lock"
elif test -f "Gemfile.lock.next"; then
  TEST_FILE="Gemfile.lock.next"
else
  echo "could not find any supported file to check"
  exit 1
fi

echo "checking $TEST_FILE with snyk"

npx snyk auth $SNYK_TOKEN
npx snyk test --severity-threshold=low --file=$TEST_FILE --org=instructure --project-name=canvas-lms:ruby --packageManager=rubygems || true
npx snyk monitor --severity-threshold=low --file=$TEST_FILE --org=instructure --project-name=canvas-lms:ruby --packageManager=rubygems
