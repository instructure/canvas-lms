#!/bin/bash
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

export JSPEC_WD=$(pwd)

# The "--silent" and "|| true" here are to supress the standard npm
# "...npm ERR! Tell the author that this fails on your system..."
# error messages if there is a spec that fails.
if [ "$1" == "--watch" ]; then
  export JSPEC_PATH=$2
  yarn test:karma:watch --silent || true
elif [ "$1" == "--a11y" ]; then
  export JSPEC_PATH=$2
  A11Y_REPORT=1 yarn test:karma:watch --silent || true
else
  export JSPEC_PATH=$1
  yarn test:karma || true
fi
