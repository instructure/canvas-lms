#!/bin/bash
result=0

echo "################ utf8_cleaner ################"
bundle check || bundle install
bundle exec rspec spec
result+=$?

if [ $result -eq 0 ]; then
  echo "SUCCESS"
else
  echo "FAILURE"
fi

exit $result
