#!/bin/bash
result=0

echo "################ active_polymorph ################"
echo "################ Running tests against Rails 2 ################"
export CANVAS_RAILS3=0
bundle check || bundle install
bundle exec rspec spec
let result=$result+$?

echo "################ Running tests against Rails 3 ################"
mv Gemfile.lock Gemfile.lock.rails2
export CANVAS_RAILS3=1
bundle check || bundle install
bundle exec rspec spec
let result=$result+$?

if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result
