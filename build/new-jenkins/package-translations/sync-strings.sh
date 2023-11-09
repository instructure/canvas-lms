#!/bin/bash

set -x -o errexit -o errtrace -o nounset -o pipefail
git config --global --add safe.directory /usr/src/app

##
# This script takes an en.json file for package translations, and sends it
# through the translation process.  It will then push up any changes in translations
# to the repo.
##

if [ ! -z "${SSH_USERNAME-}" ]; then
  export AWS_ROLE_ARN="arn:aws:iam::307761260553:role/translations-jenkins"
  export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -i /usr/src/sshkeyfile -l $SSH_USERNAME"

  # Sync crowdsourced translations, then professional translations. The order is important because the
  # second will overwrite the first if both sources have translations for a single locale. Professional
  # translations should take precedence.
  "$(yarn bin)/sync-translations" --ignore-jira --config ./package-translations/sync-config-crowd.json
  "$(yarn bin)/sync-translations" --ignore-jira --config ./package-translations/sync-config.json
fi

# Remove empty/missing strings from catalogs.
for file in packages/translations/lib/*.json; do
  if [[ "$file" == 'packages/translations/lib/en.json' ]]; then continue; fi
  jq --indent 4 'with_entries(select(.value.message != ""))' "$file" > tmp.json && mv tmp.json "$file"
done

# If there are no changes to commit, bail out
GIT_STATUS=$(git status --porcelain packages/translations/lib)
if [[ -z $(echo $GIT_STATUS | grep 'packages/translations/lib') ]]; then
  echo "No new translations to commit"
  exit 0
fi

# Split out locales to their respective package folders
# This allows consuming packages to pull in only the translations they care about
# which reduces our overall webpack bundle size later.
pushd packages/translations
yarn split
yarn lint
popd

yarn wsrun --exclude-missing installTranslations

if [ ! -z "${SSH_USERNAME-}" ]; then
  git config --global user.name "Jenkins"
  git config --global user.email "svc.cloudjenkins@instructure.com"

  gitdir=$(git rev-parse --git-dir); scp -o StrictHostKeyChecking=no -i /usr/src/sshkeyfile -p -P 29418 "${SSH_USERNAME}@gerrit.instructure.com:hooks/commit-msg" "${gitdir}/hooks/"
  # Commit any changes into a temp branch then push to gerrit
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  git checkout -q -B sync-translations-tmp && \
    git add -A packages/translations/lib && \
    git commit -m "[i18n] Update package translations" && \
    git push origin sync-translations-tmp:refs/for/master%submit,l=Verified+1 && \
    git checkout -q "$CURRENT_BRANCH"

  yarn wsrun --serial --exclude-missing commitTranslations
fi
