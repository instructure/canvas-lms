#!/bin/bash

set -ex

# Check that lockfiles haven't changed. If they did, you probably forgot to run
# `bundle install` or to commit the changed lockfiles.
bundle config --global unset frozen
bundle install

diff="$(git diff 'Gemfile*.lock')"
if [ -n "$diff" ]; then
    diff="\n\n\`\`\`\n$diff\n\`\`\`"
    diff=${diff//$'\n'/'\n'}
    diff=${diff//$'"'/'\"'}

    message="Lockfile changes were detected. Make sure you run 'bundle install'."
    gergich comment "{\"path\":\"/COMMIT_MSG\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
fi

gergich status
echo "GEMFILE_LOCK OK!"
