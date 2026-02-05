#!/bin/bash

set -e

exit_status=0

echo "Running Groovy linter..."
gergich capture custom:./build/gergich/npm_groovy_lint:Gergich::NpmGroovyLint \
  'npx npm-groovy-lint \
    --path "." \
    --ignorepattern "**/node_modules/**" \
    --files "**/*.groovy,**/Jenkinsfile*" \
    --config ".groovylintrc.json" \
    --loglevel info \
    --failon warning' || { echo "Groovy linting failed"; exit_status=1; }

gergich status
echo "GROOVY_LINT OK!"

exit $exit_status
