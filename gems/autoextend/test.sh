#!/usr/bin/env bash
set -e

bundle check || bundle install
bundle exec rspec spec
WITH_ZEITWERK=true bundle exec rspec spec
