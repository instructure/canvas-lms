#!/usr/bin/env bash

set -e

cp config/database.yml.codespaces config/database.yml &&
cp config/security.yml.example config/security.yml &&
bundle install &&
bundle exec rake db:migrate &&
bundle exec rails canvas:compile_assets_dev