#!/bin/bash
set -e

bundle check || bundle install
bundle exec ruby test/list_test.rb
