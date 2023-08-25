#!/bin/bash
set -e

bundle check || bundle install
bundle exec rspec
