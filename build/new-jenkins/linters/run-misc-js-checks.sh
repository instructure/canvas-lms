#!/bin/bash

set -e
export NODE_OPTIONS="--max-old-space-size=8192"

exit_status=0

echo "Generating plugin bundles..."
node ui-build/webpack/generatePluginBundles.js

echo "Running i18n extract..."
yarn wsrun --exclude-missing i18n:extract

echo "Running dependency cruiser..."
# reintroduce later; wasn't failing builds earlier
node_modules/.bin/depcruise ./ --include-only "^(ui|packages)" || { echo "Dependency cruiser check failed"; exit_status=1; }

echo "Validating workspace dependencies..."
node script/yarn-validate-workspace-deps.js 2>/dev/null < <(yarn --silent workspaces info --json) || { echo "Workspace dependency validation failed"; exit_status=1; }

echo "Running component info validation..."
node ui-build/tools/component-info.mjs -i -v -g || { echo "Component info validation failed"; exit_status=1; }

if [ $exit_status -ne 0 ]; then
    echo "One or more linters failed. Please fix all issues before proceeding."
fi
exit $exit_status