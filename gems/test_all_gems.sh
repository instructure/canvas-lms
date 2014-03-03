#!/bin/bash

result=0

for test_script in $(find . -name test.sh); do
  pushd `dirname $test_script` > /dev/null
  ./test.sh
  result+=$?
  popd > /dev/null
done

echo "################ RESULT FOR ALL GEMS ################"
if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result