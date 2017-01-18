#! /bin/bash
bundle check || bundle update
bundle exec rake db:migrate
bundle exec rake canvas:compile_assets
