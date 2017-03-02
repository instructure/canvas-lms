#!/bin/bash
set -e

if hash yarn 2>/dev/null; then
  yarn install
  yarn test
else
  echo "npm is deprecated in canvas-lms, install & use yarn instead"
  npm install
  npm test
fi

