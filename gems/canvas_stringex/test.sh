#!/bin/bash
result=0

echo "################ canvas_stringex ################"
bundle check || bundle install
bundle exec rspec spec
let result=$result+$?
bundle exec rake refresh_db

if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result
