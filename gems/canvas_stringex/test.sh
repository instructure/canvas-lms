#!/bin/bash

bundle check || bundle install
bundle exec rspec spec
result=$?
bundle exec rake refresh_db
exit $result
