#!/bin/bash
result=0

echo "################ Running tests against Rails 2 ################"
unset  CANVAS_RAILS3
bundle install
bundle exec rake test
let result=$result+$?
bundle exec rake refresh_db

echo "################ Running tests against Rails 3 ################"
mv Gemfile.lock Gemfile.lock.rails2
export CANVAS_RAILS3=true
bundle install
bundle exec rake test
let result=$result+$?
bundle exec rake refresh_db
mv Gemfile.lock.rails2 Gemfile.lock


if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result
