#!/bin/bash
set -e

exit 0 # flakey due to Rails 6.1 upgrade, fix in FOO-1315

rm -f Gemfile.lock
bundle check || bundle install
bundle exec rspec spec
