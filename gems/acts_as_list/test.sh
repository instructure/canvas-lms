#!/bin/bash
set -e

bundle check || bundle install
ruby test/list_test.rb
