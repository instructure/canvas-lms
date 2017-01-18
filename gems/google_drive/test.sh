#!/bin/bash
set -e

rm -f Gemfile.lock
bundle check || bundle install
bundle exec rspec spec
