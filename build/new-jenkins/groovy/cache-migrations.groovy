/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// If the migrated images are not found, then it builds from database base images
def loadMigratedImages() {
  dockerCacheLoad(image: "$POSTGRES_CACHE_TAG")
  dockerCacheLoad(image: "$CASSANDRA_CACHE_TAG")
  dockerCacheLoad(image: "$DYNAMODB_CACHE_TAG")
}

def successfullyLoadedFromCache() {
  return sh (
    script: 
      '''
        if [ ! -z "$(docker images -q $POSTGRES_CACHE_TAG 2> /dev/null)" ] &&\
           [ ! -z "$(docker images -q $CASSANDRA_CACHE_TAG 2> /dev/null)" ] &&\
           [ ! -z "$(docker images -q $DYNAMODB_CACHE_TAG 2> /dev/null)" ] ; then
           echo 'loaded'
        fi
      ''',
      returnStdout: true
  ).trim() == 'loaded'
}

def dockerUpWithoutBuild() {
  sh '''
    docker-compose up -d
    for config_name in database cassandra security dynamodb; do
      docker-compose exec -T web cp config/new-jenkins/${config_name}.yml config/${config_name}.yml
    done
  '''
}

def commitMigratedImages() {
  def commitMessage = "Postgres migrated image for patchset $NAME"
  sh 'docker commit -m \"$commitMessage\" `docker-compose ps -q postgres` $POSTGRES_CACHE_TAG'
  commitMessage = "Cassandra migrated image for patchset $NAME"
  sh 'docker commit -m \"$commitMessage\" `docker-compose ps -q cassandra` $CASSANDRA_CACHE_TAG'
  commitMessage = "Dynamodb migrated image for patchset $NAME"
  sh 'docker commit -m \"$commitMessage\" `docker-compose ps -q dynamodb` $DYNAMODB_CACHE_TAG'
}

def storeMigratedImages() {
  dockerCacheStore(image: "$POSTGRES_CACHE_TAG")
  dockerCacheStore(image: "$CASSANDRA_CACHE_TAG")
  dockerCacheStore(image: "$DYNAMODB_CACHE_TAG")
}

def createMigrateBuildUpCached() {
  loadMigratedImages()
  if(successfullyLoadedFromCache()) {
    dockerUpWithoutBuild()
    sh 'build/new-jenkins/docker-compose-create-migrate-database.sh'
  } else {
    sh 'build/new-jenkins/docker-compose-pull.sh'
    sh 'build/new-jenkins/docker-compose-build-up.sh'
    sh 'build/new-jenkins/docker-compose-create-migrate-database.sh'
  }
  commitMigratedImages()
}
return this
