#!/bin/bash

set -ex

if [ -z "$SKIP_YARN" ]; then
  read -r -a PLUGINS_LIST_ARR <<< "$PLUGINS_LIST"
  rm -rf $(printf 'gems/plugins/%s ' "${PLUGINS_LIST_ARR[@]}")

  export DISABLE_POSTINSTALL=1
  yarn install || yarn install --network-concurrency 1
fi

if ! git diff --exit-code yarn.lock; then
  #
  # Put yarn.lock diff into the build output
  #
  git --no-pager diff yarn.lock

  #
  # Put yarn.lock diff into the Gergich message
  #
  diff="$(git diff yarn.lock)"
  diff="\n\n\`\`\`\n$diff\n\`\`\`"
  diff=${diff//$'\n'/'\n'}
  diff=${diff//$'"'/'\"'}

  message="yarn.lock changes need to be checked in. Make sure you run 'yarn install' without private canvas-lms plugins installed."
  gergich comment "{\"path\":\"yarn.lock\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
else
  yarn dedupe-yarn

  if ! git diff --exit-code yarn.lock; then
    message="yarn.lock changes need to be de-duplicated. Make sure you run 'yarn dedupe-yarn'."
    gergich comment "{\"path\":\"yarn.lock\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
  fi
fi

gergich status
echo "YARN_LOCK OK!"
