#!/bin/bash

#
# Runs babel builds for each of our ES-built packages, so that changes to those
# packages are watched and get updated into the main webpack build.
#

#
# For each package, it does the following:
# 1. Clean (delete) existing es build artifacts
# 2. Rebuild the es artifacts
# 3. Watch for changes
#
# Uses `yarn concurrently` to do each phase in parallel; phase 3 also includes running
# the main webpack build in parallel
# - We do the watches in parallel so that everything is monitored
# - We do the initial build in parallel to get through it a little quicker
# - We do the clean in parallel just for consistency with the other two steps
#

PACKAGES=("canvas-rce" "canvas-media")
CLEAN_COMMANDS=()
BUILD_COMMANDS=()
WATCH_COMMANDS=()

for PACKAGE in "${PACKAGES[@]}"; do
  YARN="yarn --cwd packages/$PACKAGE"
  CLEAN_COMMANDS+=("$YARN clean:es")
  BUILD_COMMANDS+=("$YARN build:es")
  WATCH_COMMANDS+=("$YARN build:es --watch --skip-initial-build")
done

yarn concurrently "${CLEAN_COMMANDS[@]}"
yarn concurrently "${BUILD_COMMANDS[@]}"
yarn concurrently "${WATCH_COMMANDS[@]}" "yarn webpack"
