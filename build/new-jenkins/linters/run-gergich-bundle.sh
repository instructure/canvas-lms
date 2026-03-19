#!/bin/bash

set -ex

# Check that lockfiles haven't changed. If they did, you probably forgot to run
# `bundle install` or to commit the changed lockfiles.
bundle config --global unset frozen
bundle install

diff="$(git diff 'Gemfile*.lock' '**/Gemfile*.lock')"
if [ -n "$diff" ]; then
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

    message="Lockfile changes were detected. Make sure you run 'bundle install'."
    gergich comment "{\"path\":\"/COMMIT_MSG\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
fi

gergich status
echo "GEMFILE_LOCK OK!"
