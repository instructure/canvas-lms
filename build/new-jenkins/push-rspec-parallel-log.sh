#!/bin/bash
set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

rm log/parallel-runtime-rspec.log
mv parallel_logs/parallel_runtime_rspec.log log/parallel-runtime-rspec.log

REVIEWERS=${DEFAULT_REVIEWERS:-r=jbutters@instructure.com}

# Set config
git config --global user.name "Service Cloud Jenkins"
git config --global user.email "svc.cloudjenkins@instructure.com"

# Install commit hook
curl -Lo .git/hooks/commit-msg https://gerrit.instructure.com/tools/hooks/commit-msg
chmod u+x .git/hooks/commit-msg

# Delete temp branch if exists
if [ `git branch --list new_parallel_log-tmp` ]
then
  git branch -D new_parallel_log-tmp
fi

# Checkout new temp branch
git checkout -b new_parallel_log-tmp
# add file to commit
git add log/parallel-runtime-rspec.log
# commit with message
git commit -m "Update parallel_runtime_rspec.log from build $BUILD_NUMBER"
# Push to gerrit with reviewers
GIT_SSH_COMMAND='ssh -i "$SSH_KEY_PATH" -l "$SSH_USERNAME"' git push origin "new_parallel_log-tmp:refs/for/master%$REVIEWERS"
