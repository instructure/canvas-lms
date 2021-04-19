#!/bin/bash

set -o nounset -o errexit -o errtrace -o pipefail -o xtrace

bundle exec rspec spec/lib/message_bus_spec.rb
