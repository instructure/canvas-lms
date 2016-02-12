#!/bin/bash
cd ~/src/canvas-lms
dinghy up
docker-compose up
open http://canvas.docker/

# Admin user login:
# username: admin@beyondz.org
# password: test1234

