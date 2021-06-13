#!/bin/bash
set -o errexit -o errtrace -o pipefail -o xtrace

bundle exec rspec spec/contracts/service_providers/ --tag pact --format doc

if [[ "$PUBLISH_API" == "1" ]]; then
  bundle exec rake broker:pact:publish:jenkins_post_merge
fi
