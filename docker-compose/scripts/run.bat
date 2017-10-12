#!/bin/bash

# When you stop the container, it doesn't clean itself up properly so it fails to start next time. Cleanup!
if [ -e /app/tmp/pids/server.pid ]; then
  echo "Cleaning up previous server state"
  rm /app/tmp/pids/server.pid
fi

echo "Checking that bundle install doesn't need to run"
bundle check &> /dev/null
if [ $? -ne 0 ]; then
  bundle install
else
  echo "Ok!"
fi

echo "Checking if npm is installed"
if ! npm -v &> /dev/null; then
  npm install
else
  echo "Ok!"
fi

# Not sure exactly why I need this, but after stopping and starting the container it dies with
# an error saying i have to run this.  So just do it.
bundle exec rake db:reset_encryption_key_hash

#echo ""
#echo "Note: If this is the first time you're starting this container, you may have to run the following:"
#echo ""
#echo "    bundle exec rake db:create; bundle exec rake db:migrate; bundle exec rake db:initial_setup"
#echo "    bundle exec rake canvas:compile_assets"

echo "Starting the rails app"
bundle exec bin/rails s -p 3000 -b '0.0.0.0'
