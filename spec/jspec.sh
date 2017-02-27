#!/bin/bash
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# only the webapack version of the karma config works whith jspec
export USE_WEBPACK=true

export JSPEC_WD=$(pwd)

# The "--silent" and "|| true" here are to supress the standard npm
# "...npm ERR! Tell the author that this fails on your system..."
# error messages if there is a spec that fails.
if [ "$1" == "--watch" ]; then
  export JSPEC_PATH=$2
  npm run test-watch --silent || true
else
  export JSPEC_PATH=$1
  npm run test || true
fi
