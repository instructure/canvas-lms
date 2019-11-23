#!/bin/bash
# This connects to the app server and runs delayed jobs
docker-compose exec canvasweb bundle exec script/canvas_init run
