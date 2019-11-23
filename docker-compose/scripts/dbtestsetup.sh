#!/bin/bash
echo "Setting up your local canvas_test database so you can run: bundle exec rspec"

cat <<EOF | docker-compose exec -T canvasdb /bin/bash

createdb -U canvas canvas_test
psql -U canvas -c 'GRANT ALL PRIVILEGES ON DATABASE canvas_test TO canvas' -d canvas_test
psql -U canvas -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas' -d canvas_test
psql -U canvas -c 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas' -d canvas_test

EOF

docker-compose exec -T canvasweb RAILS_ENV=test bundle exec rake db:test:reset

