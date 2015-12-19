#!/bin/bash
/etc/init.d/xvfb start && sleep 2
./node_modules/karma/bin/karma start --browsers Chrome --single-run --reporters progress 2>&1
