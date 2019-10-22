#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

echo "Checking that bundle install doesn't need to run"
bundle check &> /dev/null
if [ $? -ne 0 ]; then
  echo "Bundle check FAILED / ERROR. Make sure the bundle install <ARGS> worked in the Docker container build"
  exit 1
else
  echo "Ok!"
fi

echo "Checking if npm is installed"
if ! npm -v &> /dev/null; then
  echo "npm -v FAILED / ERROR. Make sure the npm install worked in the Docker container build."
else
  echo "Ok!"
fi

cp -a /app/docker-compose/.env /app/.env

echo "Checking if the AWS ENV vars are setup"
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "The AWS ENV vars arent setup. One of the following is empty: AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
  exit 1
else
  echo "Ok!"
fi

echo "### If you get error messages telling you to run: bundle exec rake db:reset_encryption_key_hash"
echo "That will make the Canvas API access tokens invalid. The way this works is that the value of:"
echo "    select value from settings where name = 'encryption_key_hash';"
echo "Used when generating the access tokens (e.g. CANVAS_ACCESS_TOKEN) is set when creating the dev DB on the admin server"

# TODO: check if the database is already setup and if not, download and load the latest dev db.
#bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:initial_setup
echo "####"
echo "If you are building this fresh and don't have a dev database setup/loaded, run the following and then restart:"
echo ""
echo "docker-compose exec canvasweb bundle exec rake db:create"
echo "./docker-compose/scripts/dbrefresh.sh"
echo ""

echo "Starting rails app. Go to http://canvasweb:3000 to access it (assuming you've added canvasweb to /etc/hosts)"
bundle exec bin/rails s -p 3000 -b '0.0.0.0'

# TODO: when we move to heroku, switch to puma"
# Use puma to run rails instead of running it directly so that our dev env matches prod.
#echo "Starting the rails app using puma"
#bundle exec puma -C config/puma.rb
