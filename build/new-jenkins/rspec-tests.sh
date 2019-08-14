#!/bin/bash

export COMPOSE_FILE=docker-compose.new-jenkins.yml

# Todo: build the spec list similar to how it currently is in rspect
# spec_files=`find spec {gems,vendor}/plugins/*/spec_canvas -type f -name '*_spec.rb'|grep -v '/selenium/'|tr '\n' ' '`

# Todo: run the specs in spec_files
# docker-compose run web bundle exec rspec -f doc --format html --out results.html spec_files
