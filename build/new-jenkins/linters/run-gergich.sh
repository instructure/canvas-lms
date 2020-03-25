#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

inputs=()
inputs+=("--volume $WORKSPACE/.git:/usr/src/app/.git")
inputs+=("--env GERGICH_PUBLISH=$GERGICH_PUBLISH")
inputs+=("--env GERGICH_KEY=$GERGICH_KEY")
inputs+=("--env GERRIT_HOST=$GERRIT_HOST")
inputs+=("--env GERRIT_PROJECT=$GERRIT_PROJECT")
inputs+=("--env GERRIT_BRANCH=$GERRIT_BRANCH")
inputs+=("--env GERRIT_EVENT_ACCOUNT_EMAIL=$GERRIT_EVENT_ACCOUNT_EMAIL")
inputs+=("--env GERRIT_PATCHSET_NUMBER=$GERRIT_PATCHSET_NUMBER")
inputs+=("--env GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION")
inputs+=("--env GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID")
inputs+=("--env GERRIT_CHANGE_NUMBER=$GERRIT_CHANGE_NUMBER")

# the GERRIT_REFSPEC is required for the commit message to actually
# send things to gergich
inputs+=("--env GERRIT_REFSPEC=$GERRIT_REFSPEC")

cat <<EOF | docker run --interactive ${inputs[@]} $PATCHSET_TAG /bin/bash -
set -ex

# ensure we run the gergich comments with the Lint-Review label
export GERGICH_REVIEW_LABEL="Lint-Review"

# we need to remove the hooks because compile_assets calls yarn install which will
# try to create the .git commit hooks
echo "" > ./script/install_hooks
gergich capture custom:./build/gergich/compile_assets:Gergich::CompileAssets "rake canvas:compile_assets"

gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
gergich capture i18nliner "rake i18n:check"
bundle exec ruby script/brakeman
bundle exec ruby script/tatl_tael
bundle exec ruby script/stylelint
bundle exec ruby script/rlint
bundle exec ruby script/eslint
bundle exec ruby script/lint_commit_message

git status
gergich status
if [[ "$GERGICH_PUBLISH" == "1" ]]; then
  # we need to do this because it forces gergich to not use git (because no git repo is there).
  # and being that we rebased, the commit hash changes, so this will make it use the variables passed in
  export GERGICH_GIT_PATH=".."
  gergich publish
fi
EOF
