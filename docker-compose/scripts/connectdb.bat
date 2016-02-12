#!/bin/bash
docker-compose run --rm web psql -h postgres -U postgres -d canvas
