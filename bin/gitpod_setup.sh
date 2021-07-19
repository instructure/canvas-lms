# Get a version of Canvas LMS running as quickly as possible (e.g. for a development environment)
# https://github.com/instructure/canvas-lms/wiki/Quick-Start

# Install Canvas Dependencies
bundle install
yarn install --pure-lockfile

# Data Setup
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration; do cp -v config/$config.yml.example config/$config.yml; done 

# Dynamic settings configuration
cp config/dynamic_settings.yml.example config/dynamic_settings.yml

# File Generation
bundle exec rails canvas:compile_assets

# Database configuration
cp config/database.yml.example config/database.yml
createdb canvas_development

# Database population
export CANVAS_LMS_ADMIN_EMAIL=snatarajan@instructure.com && export CANVAS_LMS_ADMIN_PASSWORD=password && export CANVAS_LMS_STATS_COLLECTION=opt_out && export CANVAS_LMS_ACCOUNT_NAME=inst
bundle exec rails db:initial_setup

# Test database configuration
psql -c 'CREATE USER canvas' -d postgres
psql -c 'ALTER USER canvas CREATEDB' -d postgres
createdb -U canvas canvas_test
psql -c 'GRANT ALL PRIVILEGES ON DATABASE canvas_test TO canvas' -d canvas_test
psql -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas' -d canvas_test
psql -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas' -d canvas_test
RAILS_ENV=test bundle exec rails db:test:reset

# Performance Tweaks
# Installing redis will significantly improve your Canvas performance
echo -e "development:\n  cache_store: redis_store" > config/cache_store.yml
echo -e "development:\n  servers:\n  - redis://localhost" > config/redis.yml
# Enable class caching
echo -n 'config.cache_classes = true
' > config/environments/development-local.rb
