#!/bin/bash
result=0

echo "################ google_docs ################"
rm -f Gemfile.lock
bundle install
bundle exec rspec spec
let result=$result+$?

if [ $result -eq 0 ]; then
  echo "SUCCESS"
else
  echo "FAILURE"
fi

exit $result
