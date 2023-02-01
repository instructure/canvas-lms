#!/bin/bash

set -ex

# Check that the partial lockfile is as expected with all private plugins installed.
# If this step fails - you probably just didn't commit Gemfile.lock or committed a bad
# version somehow.
bundle install

for f in Gemfile.rails*.lock.partial; do
  if ! git diff --exit-code $f; then
    export SKIP_OSS_CHECK=1

    git --no-pager diff $f

    diff="$(git diff $f)"
    diff="\n\n\`\`\`\n$diff\n\`\`\`"
    diff=${diff//$'\n'/'\n'}
    diff=${diff//$'"'/'\"'}

    message="$f changes were detected when private plugins are installed. Make sure you run 'bundle install'."
    gergich comment "{\"path\":\"$f\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
  fi
done

# If this is a plugin build and the change would require Gemfile.lock, the above
# check would catch the issue and the corresponding canvas-lms build would catch
# OSS issues.
if [[ "$SKIP_OSS_CHECK" != "1" || "$GERRIT_PROJECT" == "canvas-lms" ]]; then
  read -r -a PLUGINS_LIST_ARR <<< "$PLUGINS_LIST"
  rm -rf $(printf 'gems/plugins/%s ' "${PLUGINS_LIST_ARR[@]}")

  # Check that the partial lockfile is as expected with no private plugins installed.
  # If this step fails - it's likely that one of the constraints is being violated:
  #
  # 1. All dependencies under a private source must be pinned in the private plugin gemspec
  # 2. All sub-dependencies of (1) must be pinned in plugins.rb
  # 3. All additional public dependencies of private plugins must be pinned in plugins.rb
  bundle install

  for f in Gemfile.rails*.lock.partial; do
    if ! git diff --exit-code $f; then
      git --no-pager diff $f

      diff="$(git diff $f)"
      diff="\n\n\`\`\`\n$diff\n\`\`\`"
      diff=${diff//$'\n'/'\n'}
      diff=${diff//$'"'/'\"'}

      message="$f changes were detected when private plugins are not installed. Make sure you adhere to the version pin constraints."
      gergich comment "{\"path\":\"$f\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
    fi
  done
else
  echo "skipping OSS check due to previous failure"
fi

gergich status
echo "GEMFILE_LOCK OK!"
