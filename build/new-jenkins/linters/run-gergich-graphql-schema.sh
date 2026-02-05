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
  # Truncate diff if it's too large for Gerrit (16KB limit)
  # Count lines and truncate to first 200 lines if needed
  line_count=$(echo "$diff" | wc -l)
  if [ "$line_count" -gt 200 ]; then
      diff_truncated="$(echo "$diff" | head -n 200)"
      diff_suffix="\n\n... (diff truncated after 200 lines, see build logs for full diff)"
      diff="\n\n\`\`\`\n$diff_truncated\n\`\`\`$diff_suffix"
  else
      diff="\n\n\`\`\`\n$diff\n\`\`\`"
  fi
  diff=${diff//$'\n'/'\n'}
  diff=${diff//$'"'/'\"'}

  message="schema.graphql changes need to be checked in. Make sure you run 'rake graphql:schema' to regenerate the schema after GraphQL changes."
  gergich comment "{\"path\":\"schema.graphql\",\"position\":1,\"severity\":\"error\",\"message\":\"$message$diff\"}"
fi


gergich status
echo "GRAPHQL_SCHEMA OK!"