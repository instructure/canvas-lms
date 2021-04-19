docker-compose down
docker-compose up -d postgres
docker-compose exec -u postgres postgres /docker-entrypoint-initdb.d/10-config.sh
docker-compose exec -u postgres postgres /docker-entrypoint-initdb.d/20-replication.sh
docker-compose down # postgres must be restarted for the changes to take effect

echo "configuration complete - run 'docker-compose up -d' to start canvas"
