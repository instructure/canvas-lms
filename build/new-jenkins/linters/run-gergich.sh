#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

inputs=()
inputs+=("--volume $WORKSPACE/.git:/usr/src/app/.git")
inputs+=("--env GERGICH_PUBLISH=$GERGICH_PUBLISH")
inputs+=("--env GERGICH_KEY=$GERGICH_KEY")
inputs+=("--env GERRIT_HOST=$GERRIT_HOST")
inputs+=("--env GERRIT_PROJECT=$GERRIT_PROJECT")
inputs+=("--env GERRIT_BRANCH=$GERRIT_BRANCH")

# the GERRIT_REFSPEC is required for the commit message to actually
# send things to gergich
inputs+=("--env GERRIT_REFSPEC=$GERRIT_REFSPEC")

cat <<EOF | docker run --interactive ${inputs[@]} $PATCHSET_TAG /bin/bash -
set -ex

# the linters expect this to be here else it will just look at master
export GERRIT_PATCHSET_REVISION=`git rev-parse HEAD`

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

RAILS_ENV=test bundle exec rails graphql:schema
# if the generated file is different from the checked in file, fail
if ! git diff --exit-code schema.graphql; then
  message="GraphQL Schema changes are not checked in: run 'bundle exec rails graphql:schema' to generate graphql.schema file"
  gergich comment "{\"path\":\"schema.graphql\",\"position\":1,\"severity\":\"error\",\"message\":\"\$message\"}"
fi

gergich status
if [[ "$GERGICH_PUBLISH" == "1" ]]; then
  gergich publish
fi
EOF
