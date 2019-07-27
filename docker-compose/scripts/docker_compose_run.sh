#!/bin/bash

#sleep 15s until db is up and running
sleep 15

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

cp -a /app/docker-compose/config/* /app/config/

# Not sure exactly why I need this, but after stopping and starting the container it dies with
# an error saying i have to run this.  So just do it.
bundle exec rake db:reset_encryption_key_hash

# TODO: check if everything is setup and skip this step if so.
bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:initial_setup

#TODO: check if everything is setup and if not run this automatically. This stuff takes awhile and we only want to do it once, or if necessary.
#echo ""
#echo "Note: If this is the first time you're starting this container, you may have to run the following:"
#echo ""
#echo "    bundle exec rake canvas:compile_assets"

echo "Starting the rails app using puma"
#bundle exec bin/rails s -p 3000 -b '0.0.0.0'
# Use puma to run rails instead of running it directly so that our dev env matches prod.
bundle exec puma -C config/puma.rb
