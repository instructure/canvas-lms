#!/bin/bash
result=0

echo "################ Running tests against Rails 2 ################"
unset  CANVAS_RAILS3
bundle install
bundle exec rake test
result+=$?

echo "################ Running tests against Rails 3 ################"
rm -f Gemfile.lock
export CANVAS_RAILS3=true
bundle install
bundle exec rake test
result+=$?


if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result