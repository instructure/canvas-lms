#!/usr/bin/env bash

set -e

sudo update-rc.d redis-server enable

ruby -rerb -e 'puts ERB.new(File.read(".devcontainer/domain.yml.erb")).result(binding)' > config/domain.yml &&
cp config/database.yml.codespaces config/database.yml &&
cp config/security.yml.example config/security.yml &&
cp .devcontainer/cache_store.yml config/cache_store.yml &&
cp .devcontainer/redis.yml config/redis.yml &&
bundle install &&
yarn install &&
CANVAS_LMS_STATS_COLLECTION=opt_out \
CANVAS_LMS_ACCOUNT_NAME=learn_good_things_school \
CANVAS_LMS_ADMIN_EMAIL=admin@example.com \
CANVAS_LMS_ADMIN_PASSWORD=secret123 \
    bundle exec rake db:initial_setup &&
bundle exec rails canvas:compile_assets_dev