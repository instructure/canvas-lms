/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

cachedMigrationsHash = null
cachedCassandraTag = null
cachedDynamodbTag = null
cachedPostgresTag = null
MIGRATIONS_FILE = 'migrations.md5'

def log(message) {
  echo "[migrations.groovy]: ${message}"
}

def migrationHash() {
  if(cachedMigrationsHash) {
    return cachedMigrationsHash
  } else if(!fileExists(MIGRATIONS_FILE)) {
    try {
      unstash name: "migrations_md5sum"
    } catch(Exception ex) {
      sh "build/new-jenkins/migrate-md5sum.sh > $MIGRATIONS_FILE"

      stash name: "migrations_md5sum", includes: MIGRATIONS_FILE
    }
  }

  cachedMigrationsHash = sh(
    script: "cat $MIGRATIONS_FILE",
    returnStdout: true
  ).trim()

  return cachedMigrationsHash
}

def imageMergeTag(name) {
  return "${configuration.buildRegistryPath()}-$name-migrations:${configuration.gerritBranch()}-${migrationHash()}"
}

def imagePatchsetTag(name) {
  return "${configuration.buildRegistryPath()}-$name-migrations:${imageTagVersion()}-${imageTag.suffix()}-${migrationHash()}"
}

def cassandraTag() {
  return cachedCassandraTag
}

def dynamodbTag() {
  return cachedDynamodbTag
}

def postgresTag() {
  return cachedPostgresTag
}

def cacheLoadFailed() {
  return sh(
    script: """
      DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect ${imageMergeTag('postgres')} && \
      DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect ${imageMergeTag('cassandra')} && \
      DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect ${imageMergeTag('dynamodb')}
    """,
    returnStatus: true
  ) != 0
}

def runMigrations() {
  if (configuration.getBoolean('skip-cache') || cacheLoadFailed() || configuration.isChangeMerged()) {
    log('Ignoring any previously cached migrations and migrating from scratch.')

    cachedCassandraTag = configuration.isChangeMerged() ? imageMergeTag('cassandra') : imagePatchsetTag('cassandra')
    cachedDynamodbTag = configuration.isChangeMerged() ? imageMergeTag('dynamodb') : imagePatchsetTag('dynamodb')
    cachedPostgresTag = configuration.isChangeMerged() ? imageMergeTag('postgres') : imagePatchsetTag('postgres')

    sh 'build/new-jenkins/docker-compose-pull.sh'
    sh 'build/new-jenkins/docker-compose-build-up.sh'
    sh 'build/new-jenkins/docker-compose-setup-databases.sh'

    def postgresMessage = "Postgres migrated image for MD5SUM ${migrationHash()}"
    sh "docker commit -m \"${postgresMessage}\" \$(docker ps -q --filter 'name=postgres_') ${cachedPostgresTag}"
    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push ${cachedPostgresTag}"

    def cassandraMessage = "Cassandra migrated image for MD5SUM ${migrationHash()}"
    sh "docker commit -m \"${cassandraMessage}\" \$(docker ps -q --filter 'name=cassandra_') ${cachedCassandraTag}"
    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push ${cachedCassandraTag}"

    def dynamodbMessage = "Dynamodb migrated image for MD5SUM ${migrationHash()}"
    sh "docker commit -m \"${dynamodbMessage}\" \$(docker ps -q --filter 'name=dynamodb_') ${cachedDynamodbTag}"
    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push ${cachedDynamodbTag}"
  } else {
    log('Continuing with previously cached migrations.')

    cachedCassandraTag = imageMergeTag('cassandra')
    cachedDynamodbTag = imageMergeTag('dynamodb')
    cachedPostgresTag = imageMergeTag('postgres')
  }
}

return this
