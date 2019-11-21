#!/usr/bin/env bash
set -e

bundle check || bundle install
bundle exec rspec spec
