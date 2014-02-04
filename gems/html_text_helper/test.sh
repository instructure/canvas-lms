result=0

echo "################ Running tests against Rails 2 ################"
unset  CANVAS_RAILS3
bundle install
bundle exec rspec spec
result+=$?


echo "################ Running tests against Rails 3 ################"
rm -f Gemfile.lock
export CANVAS_RAILS3=true
bundle install
bundle exec rspec spec
result+=$?


if [ $result -eq 0 ]; then
  echo "SUCCESS"
else
  echo "FAILURE"
fi

exit $result