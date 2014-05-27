#!/bin/bash
result=0

echo "################ json_token ################"
bundle install
bundle exec rspec spec
let result=$result+$?

if [ $result -eq 0 ]; then
    echo "SUCCESS"
else
    echo "FAILURE"
fi

exit $result
