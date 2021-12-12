#!/bin/bash
# Commands to run to configure the devcontainer after it starts (since they require files in the repo).
sudo gem install bundle
sudo gem install bundler -v 2.2.30
sudo gem install nokogumbo scrypt sanitize
sudo chown -R vscode:vscode /workspaces/canvas-lms/
sudo chown -R vscode:vscode /var/lib/gems/2.7.0/
bundle _2.2.30_ install --without pulsar
yarn install --pure-lockfile
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; \
          do cp -v config/$config.yml.example config/$config.yml; done
sudo chown -R vscode:vscode /var/lib/gems/2.7.0/
bundle _2.2.30_ update
bundle exec rails canvas:compile_assets
sudo chown -R vscode:vscode /var/run/postgresql/
export PGHOST=localhost
/usr/lib/postgresql/12/bin/initdb ~/postgresql-data/ -E utf8
/usr/lib/postgresql/12/bin/pg_ctl -D ~/postgresql-data/ -l ~/postgresql-data/server.log start
/usr/lib/postgresql/12/bin/createdb canvas_development
# Set correct domain for port forwarding on Codespaces. npx package was developed by a GitHub employee, since you can't get the URL directly in the codespace yet.
if [ ! -z ${CODESPACES+x} ]
then
    sed -i "s/localhost:3000/$(npx -y codespaces-port 3000 | cut -c 9-)/g" config/domain.yml
fi
touch /home/vscode/.setupDone
# bundle exec rails db:initial_setup