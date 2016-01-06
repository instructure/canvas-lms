#!/usr/bin/env bash

bundle check || bundle install

bundle exec rake spec

exit $?
