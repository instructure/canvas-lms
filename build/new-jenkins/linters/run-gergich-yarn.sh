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
  # Truncate diff if it's too large for Gerrit (16KB limit)
  # Count lines and truncate to first 200 lines if needed
  line_count=$(echo "$diff" | wc -l)
  if [ "$line_count" -gt 200 ]; then
      diff_truncated="$(echo "$diff" | head -n 200)"
      diff_suffix="\n\n... (diff truncated after 200 lines, see build logs for full diff)"
      diff="\n\n\`\`\`\n$diff_truncated\n\`\`\`$diff_suffix"
  else
      diff="\n\n\`\`\`\n$diff\n\`\`\`"
  fi
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

# Check if @swc/core is updated without swc-plugin-coverage-instrument
if git diff HEAD^ package.json | grep -q '@swc/core'; then
  if ! git diff HEAD^ package.json | grep -q 'swc-plugin-coverage-instrument'; then
    message="@swc/core was updated without updating swc-plugin-coverage-instrument. These packages must be compatible or the Crystalball build will fail. Verify compatibility at https://plugins.swc.rs/ or update swc-plugin-coverage-instrument to a compatible version."
    gergich comment "{\"path\":\"package.json\",\"position\":1,\"severity\":\"warn\",\"message\":\"$message\"}"
  fi
fi

gergich status
echo "YARN_LOCK OK!"
