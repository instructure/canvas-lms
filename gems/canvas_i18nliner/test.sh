#!/bin/bash
result=0

echo "################ canvas_i18nliner ################"
npm install
npm test
let result=$result+$?

if [ $result -eq 0 ]; then
  echo "SUCCESS"
else
  echo "FAILURE"
fi

exit $result
