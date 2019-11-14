#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail

# the GERRIT_REFSPEC is required for the commit message to actually
# send things to gergich
cat <<EOF | docker run --interactive \
  --volume $WORKSPACE/.git:/usr/src/app/.git \
  --env GERGICH_PUBLISH=$GERGICH_PUBLISH \
  --env GERRIT_REFSPEC=$GERRIT_REFSPEC \
  --env GERGICH_KEY=$GERGICH_KEY \
  --env GERRIT_HOST=$GERRIT_HOST \
  --env GERRIT_PROJECT=$GERRIT_PROJECT \
  --env GERRIT_BRANCH=$GERRIT_BRANCH \
  $PATCHSET_TAG /bin/bash -
set -ex

# the linters expect this to be here else it will just look at master
export GERRIT_PATCHSET_REVISION=`git rev-parse HEAD`

gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
gergich capture i18nliner "rake i18n:check"
bundle exec ruby script/brakeman
bundle exec ruby script/tatl_tael
bundle exec ruby script/stylelint
bundle exec ruby script/rlint
bundle exec ruby script/eslint
bundle exec ruby script/lint_commit_message

# this is here to remind us that we need to add this during compile once we
# figure out the write issues with a mounted volume of gergich
# bundle exec gergich capture custom:./build/gergich/compile_assets:Gergich::CompileAssets "rake canvas:compile_assets"

gergich comment '{"path":"gergich-test.rb","position":3,"severity":"info","message":"from-new-jenkins"}'

gergich status
if [[ "$GERGICH_PUBLISH" == "1" ]]; then
  gergich publish
fi
EOF
