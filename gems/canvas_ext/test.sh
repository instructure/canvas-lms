#!/bin/bash
result=0

echo "################ Running tests against Rails 2 ################"
export CANVAS_RAILS3=0
bundle install
bundle exec rspec spec
let result=$result+$?

echo "################ Running tests against Rails 3 ################"
rm -f Gemfile.lock
export CANVAS_RAILS3=true
bundle install
bundle exec rspec spec
let result=$result+$?

if [ $result -eq 0 ]; then
  echo "SUCCESS"
else
  echo "FAILURE"
fi

exit $result
