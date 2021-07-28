#!/bin/bash

set -ex

read -r -a PLUGINS_LIST_ARR <<< "$PLUGINS_LIST"
rm -rf $(printf 'gems/plugins/%s ' "${PLUGINS_LIST_ARR[@]}")

export DISABLE_POSTINSTALL=1
yarn install --ignore-optional || yarn install --ignore-optional --network-concurrency 1

if ! git diff --exit-code yarn.lock; then
  message="yarn.lock changes need to be checked in. Make sure you run 'yarn install' without private canvas-lms plugins installed."
  gergich comment "{\"path\":\"yarn.lock\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
else
  yarn dedupe-yarn

  if ! git diff --exit-code yarn.lock; then
    message="yarn.lock changes need to be de-duplicated. Make sure you run 'yarn dedupe-yarn'."
    gergich comment "{\"path\":\"yarn.lock\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
  fi
fi

gergich status
echo "YARN_LOCK OK!"
