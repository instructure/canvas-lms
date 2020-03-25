#!/bin/bash

set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

echo "Setting up config files, if pre-existing config files are found, they \
will be backed up once with the '.bak' suffix'"

for config_name in database cassandra security dynamodb; do
  SOURCE=config/new-jenkins/${config_name}.yml
  DESTINATION=config/${config_name}.yml

  docker-compose exec -T web bash <<SCRIPT
    if [ ! -f "${SOURCE}" ]; then
      echo "${SOURCE} does not exist!" >&2
      exit 1
    else
      # save original copies for when this is ran on local dev environments
      # this way original configs aren't clobbered since they're not tracked in git
      if [ -f "$DESTINATION" ]; then
        # -n will avoid overwritting existing backups without also raising a failure
        mv -nv "$DESTINATION" "$DESTINATION".bak
      fi
      cp -v "$SOURCE" "$DESTINATION"
    fi
SCRIPT
done

docker-compose exec -T cassandra ./wait-for-it
# wait-for-it is currently missing
# docker-compose exec -T dynamodb ./wait-for-it
for keyspace in auditors global_lookups page_views; do
  docker-compose exec -T cassandra cqlsh -e "CREATE KEYSPACE IF NOT EXISTS ${keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
done

docker-compose exec -T -e VERBOSE=false web bundle exec rails db:create db:migrate
docker-compose exec -T web bundle exec rails runner "require 'switchman/test_helper'; Switchman::TestHelper.recreate_persistent_test_shards"
