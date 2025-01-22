#!/bin/bash

set -e
export NODE_OPTIONS="--max-old-space-size=8192"

exit_status=0

# The output of the below script is "ui/shared/bundles/extensions.ts" which is referred by several JS/TS files 
# in the following way (import extensions from '@canvas/bundles/extensions'). If the file does not exist,
# the TypeScript type checking will fail.
echo "Generating plugin extensions..."
node ui-build/webpack/generatePluginExtensions.js || { echo "Generating plugin extensions failed"; exit_status=1; }

echo "Running TypeScript type check..."
node_modules/.bin/tsc -p tsconfig.json --noEmit || { echo "TypeScript type checking failed"; exit_status=1; }

exit $exit_status
