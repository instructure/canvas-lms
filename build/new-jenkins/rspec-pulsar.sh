#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

bundle exec rspec \
  spec/lib/message_bus_spec.rb \
  spec/lib/message_bus/ca_cert_spec.rb \
  spec/models/asset_user_access_log_spec.rb
