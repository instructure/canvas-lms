CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

git checkout -B sync-translations-rce && \
  git add . && \
  git commit -m "[i18n] Update RCE translations.
After submitting, make sure to publish a new version of canvas-rce to NPM." && \
  git push origin sync-translations-rce:refs/for/master%t=learning-materials,l=Verified+1,l=Lint-Review+1 && \
  git checkout $CURRENT_BRANCH
