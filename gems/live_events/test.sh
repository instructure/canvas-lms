#!/bin/bash
set -e

bundle check || bundle install || bundle update
bundle exec rspec spec
