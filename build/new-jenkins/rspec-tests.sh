#!/bin/bash

# Todo: build the spec list similar to how it currently is in rspect
# spec_files=`find spec {gems,vendor}/plugins/*/spec_canvas -type f -name '*_spec.rb'|grep -v '/selenium/'|tr '\n' ' '`

# Todo: run the specs in spec_files
# -O spec/spec.opts runs rspec with our formatters for failure reports
docker-compose exec -T web bundle exec rspec -O spec/spec.opts spec/lib/*_spec.rb
