#!/bin/bash
export RAILS_ENV=test
bundle install
cd /usr/src/canvas-lms
rake db:initial_setup
./bin/rspec spec/pipeline
