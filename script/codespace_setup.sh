#!/bin/bash
set -ex

# https://github.com/instructure/canvas-lms/wiki/Quick-Start#github-codespaces-setup

sudo apt-get update
sudo apt-get -y install ruby ruby-dev postgresql-12 zlib1g-dev libxml2-dev libsqlite3-dev libpq-dev libxmlsec1-dev curl build-essential

sudo gem install bundle
sudo gem install bundler:2.2.30
sudo gem install nokogumbo scrypt sanitize
sudo chown -R codespace:codespace /workspaces/canvas-lms
sudo chown -R codespace:codespace /var/lib/gems/2.7.0/
bundle _2.2.30_ install
yarn install --pure-lockfile

for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; \
          do cp -v config/$config.yml.example config/$config.yml; done

sudo chown -R codespace:codespace /var/lib/gems/2.7.0/
bundle _2.2.30_ update

sudo chown -R codespace:codespace /var/run/postgresql/
export PGHOST=localhost
/usr/lib/postgresql/12/bin/initdb ~/postgresql-data/ -E utf8
/usr/lib/postgresql/12/bin/pg_ctl -D ~/postgresql-data/ -l ~/postgresql-data/server.log start
/usr/lib/postgresql/12/bin/createdb canvas_development

bundle exec rails canvas:compile_assets
bundle exec rails db:initial_setup
