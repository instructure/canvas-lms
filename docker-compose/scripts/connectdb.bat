#!/bin/bash
docker-compose run --rm canvasweb psql -h canvasdb -U postgres -d canvas
