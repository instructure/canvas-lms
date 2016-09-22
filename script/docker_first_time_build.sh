#! /bin/bash

# clean up old stuff
rm -rf vendor/bundle node_modules Gemfile.lock
bundle update
npm install
bundle exec rake db:create db:initial_setup
script/docker_update_build.sh
