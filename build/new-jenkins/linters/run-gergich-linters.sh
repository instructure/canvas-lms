#!/bin/bash

set -ex
if [ "$GERRIT_PROJECT" == "canvas-lms" ]; then
  # when parent is not in $GERRIT_BRANCH (i.e. master)
  if ! git merge-base --is-ancestor HEAD~1 origin/$GERRIT_BRANCH; then
    message="This commit is built upon commits not currently merged in $GERRIT_BRANCH. Ensure that your dependent patchsets are merged first!\\n"
    gergich comment "{\"path\":\"/COMMIT_MSG\",\"position\":1,\"severity\":\"warn\",\"message\":\"$message\"}"
  fi

  # when modifying Dockerfile or Dockerfile.jenkins*, Dockerfile.template must also be modified.
  ruby build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile
  ruby build/dockerfile_writer.rb --env jenkins --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile.jenkins
  if ! git diff --exit-code Dockerfile; then
    message="Dockerfile and build/Dockerfile.template need to be kept in sync. Update Dockerfile by running the command given at the top.\\n"
    gergich comment "{\"path\":\"\Dockerfile\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
  fi
  if ! git diff --exit-code Dockerfile.jenkins; then
    message="Dockerfile.jenkins and build/Dockerfile.template need to be kept in sync. Update Dockerfile.jenkins by running the command given at the top.\\n"
    gergich comment "{\"path\":\"\Dockerfile.jenkins\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
  fi
fi

cp ui/shared/apollo/fragmentTypes.json ui/shared/apollo/fragmentTypes.json.old

# always keep the graphQL schema up-to-date
bin/rails graphql:schema RAILS_ENV=test

if ! diff ui/shared/apollo/fragmentTypes.json ui/shared/apollo/fragmentTypes.json.old; then
  message="ui/shared/apollo/fragmentTypes.json needs to be kept up-to-date. Run bundle exec rake graphql:schema and push the changes.\\n"
  gergich comment "{\"path\":\"ui/shared/apollo/fragmentTypes.json\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
fi

gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint 'node script/xsslint.js'
gergich capture i18nliner 'bin/rails i18n:check'
# purposely don't run under bundler; they shell out and use bundler as necessary
ruby script/brakeman

read -ra PRIVATE_PLUGINS_ARR <<< "$PRIVATE_PLUGINS"

if [[ ! "${PRIVATE_PLUGINS[*]}" =~ "$GERRIT_PROJECT" ]]; then
  ruby script/tatl_tael
fi

if ! git diff HEAD~1 --exit-code -GENV -- 'packages/canvas-rce/**/*.js' 'packages/canvas-rce/**/*.jsx' 'packages/canvas-rce/**/*.ts' 'packages/canvas-rce/**/*.tsx'; then
  message="It looks like you added a reference to a Canvas ENV key inside the RCE. Instead, you should pass this value via a prop the RCEWrapper.\\n"
  gergich comment "{\"path\":\"/COMMIT_MSG\",\"position\":1,\"severity\":\"error\",\"message\":\"$message\"}"
fi

node ui-build/webpack/generatePluginBundles.js
ruby script/tsc & TSC_PID=$!
ruby script/stylelint
ruby script/rlint --no-fail-on-offense
[ "${SKIP_ESLINT-}" != "true" ] && ruby script/eslint
ruby script/lint_commit_message
node script/yarn-validate-workspace-deps.js 2>/dev/null < <(yarn --silent workspaces info --json)
node ui-build/tools/component-info.mjs -i -v -g

bin/rails css:styleguide doc:api

wait $TSC_PID
gergich status
echo "LINTER OK!"
