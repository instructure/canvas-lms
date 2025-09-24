#!/bin/bash

set -ex

# Regenerate GraphQL schema and possible types
bin/rails graphql:schema RAILS_ENV=test

if ! git diff --exit-code schema.graphql; then
  #
  # Put schema.graphql diff into the build output
  #
  git --no-pager diff schema.graphql

  #
  # Put schema.graphql diff into the Gergich message
  #
  diff="$(git diff schema.graphql)"
  diff="\n\n\`\`\`\n$diff\n\`\`\`"
  diff=${diff//$'\n'/'\n'}
  diff=${diff//$'"'/'\"'}

  message="schema.graphql changes need to be checked in. Make sure you run 'rake graphql:schema' to regenerate the schema after GraphQL changes."
  gergich comment "{\"path\":\"schema.graphql\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
fi


gergich status
echo "GRAPHQL_SCHEMA OK!"