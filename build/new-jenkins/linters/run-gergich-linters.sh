#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

cat <<EOF | docker run \
  $DOCKER_INPUTS \
  --env SKIP_ESLINT \
  --interactive \
  --volume $GERGICH_VOLUME:/home/docker/gergich \
  local/gergich /bin/bash -
set -ex
# when parent is not in \$GERRIT_BRANCH (i.e. master)
if ! git merge-base --is-ancestor HEAD~1 \$GERRIT_BRANCH; then
  message="This commit is built upon commits not currently merged in \$GERRIT_BRANCH. Ensure that your dependent patchsets are merged first!\\n"
  gergich comment "{\"path\":\"/COMMIT_MSG\",\"position\":1,\"severity\":\"warn\",\"message\":\"\$message\"}"
fi

# when modifying Dockerfile or Dockerfile.jenkins*, Dockerfile.template must also be modified.
ruby build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile
ruby build/dockerfile_writer.rb --env jenkins --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile.jenkins
if ! git diff --exit-code Dockerfile; then
  message="This commit makes changes to Dockerfile but does not update the Dockerfile.template. Ensure your changes are included in build/Dockerfile.template.\\n"
  gergich comment "{\"path\":\"\Dockerfile\",\"position\":1,\"severity\":\"error\",\"message\":\"\$message\"}"
fi
if ! git diff --exit-code Dockerfile.jenkins; then
  message="This commit makes changes to Dockerfile.jenkins but does not update the Dockerfile.template. Ensure your changes are included in build/Dockerfile.template.\\n"
  gergich comment "{\"path\":\"\Dockerfile.jenkins\",\"position\":1,\"severity\":\"error\",\"message\":\"\$message\"}"
fi

gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint 'node script/xsslint.js'
gergich capture i18nliner 'rake i18n:check'
bundle exec ruby script/brakeman
bundle exec ruby script/tatl_tael
bundle exec ruby script/stylelint
bundle exec ruby script/rlint
[ "\${SKIP_ESLINT-}" != "true" ] && bundle exec ruby script/eslint
bundle exec ruby script/lint_commit_message

gergich status
echo "LINTER OK!"
EOF
