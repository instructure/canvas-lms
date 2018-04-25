#!/bin/bash
export RAILS_ENV=test
cd /usr/src/canvas-lms
./bin/rspec spec/pipeline
