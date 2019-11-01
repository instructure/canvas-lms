#!/bin/bash
echo "Build is done, deploying container!"
echo "Testing enc vars: This is in heroku config but now in heroku.yml. What's the value? BZ_BASE_URL=$BZ_BASE_URL" 
echo "This is in heroku.yml and heroky config. Value? LOGGER_TYPE=$LOGGER_TYPE" 
