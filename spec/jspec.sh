#!/bin/bash

export JSPEC_WD=$(pwd)

if [ "$1" == "--watch" ]; then
  export JSPEC_PATH=$2
  npm run webpack-test-watch --silent || true
else
  export JSPEC_PATH=$1
  npm run webpack-test --silent && npm run test --silent || true
fi
