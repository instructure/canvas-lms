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

def log(message) {
  echo "[cache-migrations.groovy]: ${message}"
}

def prefix() { return "Canvas" }
def postgresImage() { return  "$POSTGRES_CACHE_TAG" }
def cassandraImage() { return "$CASSANDRA_CACHE_TAG" }
def dynamodbImage() { return "$DYNAMODB_CACHE_TAG" }

def cacheLoadFailed() {
  def key = 'loaded'
  return sh(
    script: """\
      [ ! -z "\$(docker images -q ${postgresImage()} 2> /dev/null)" ] \
        && [ ! -z "\$(docker images -q ${cassandraImage()} 2> /dev/null)" ] \
        && [ ! -z "\$(docker images -q ${dynamodbImage()} 2> /dev/null)" ] \
        && echo "${key}"
    """,
    returnStdout: true
  ).trim() != key
}

def commitMigratedImages() {
  def postgresMessage = "Postgres migrated image for patchset $NAME"
  sh "docker commit -m \"${postgresMessage}\" \$(docker ps -q --filter 'name=postgres_') ${postgresImage()}"

  def cassandraMessage = "Cassandra migrated image for patchset $NAME"
  sh "docker commit -m \"${cassandraMessage}\" \$(docker ps -q --filter 'name=cassandra_') ${cassandraImage()}"

  def dynamodbMessage = "Dynamodb migrated image for patchset $NAME"
  sh "docker commit -m \"${dynamodbMessage}\" \$(docker ps -q --filter 'name=dynamodb_') ${dynamodbImage()}"
}

def loadMigratedImages() {
  dockerCacheLoad(image: postgresImage(), prefix: prefix())
  dockerCacheLoad(image: cassandraImage(), prefix: prefix())
  dockerCacheLoad(image: dynamodbImage(), prefix: prefix())
}

def pullAndBuild() {
  sh 'build/new-jenkins/docker-compose-pull.sh'
  sh 'docker-compose build'
}

def startAndMigrate() {
  sh 'docker-compose up -d'
  sh 'build/new-jenkins/docker-compose-setup-databases.sh'
}

def storeMigratedImages() {
  dockerCacheStore(image: postgresImage(), prefix: prefix())
  dockerCacheStore(image: cassandraImage(), prefix: prefix())
  dockerCacheStore(image: dynamodbImage(), prefix: prefix())
}

// use cached images if available
def createMigrateBuildUpCached() {
  def flags = load 'build/new-jenkins/groovy/commit-flags.groovy'
  if (flags.hasFlag('skip-cache')) {
    log('Build cache is disabled! Ignoring any previously cached migrations and migrating from scratch.')
    pullAndBuild()
    startAndMigrate()
  } else {
    loadMigratedImages() // load images from docker cache

    // detect if load was successfull, otherwise
    if(cacheLoadFailed()) {
      pullAndBuild() // build as normal
    }

    // migrate and commit images
    startAndMigrate()
    commitMigratedImages()
  }
}

return this
