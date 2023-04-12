/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

def call() {
  credentials.withStarlordCredentials {
    // The switchman gem is likely enough to commonly break migrations that it
    // deserves its own special case to always run migrations so we don't fail
    // post-merge builds unnecessarily.
    def cacheLoadScope = configuration.isChangeMerged() || setupStage.getPinnedVersionFlag('switchman') ? '' : env.IMAGE_CACHE_MERGE_SCOPE
    def cacheSaveScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : ''

    withEnv([
      "CACHE_LOAD_SCOPE=${cacheLoadScope}",
      "CACHE_SAVE_SCOPE=${cacheSaveScope}",
      "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
      "CASSANDRA_IMAGE_TAG=${imageTag.cassandra()}",
      "CASSANDRA_PREFIX=${env.CASSANDRA_PREFIX}",
      'COMPOSE_FILE=docker-compose.new-jenkins.yml',
      "DYNAMODB_IMAGE_TAG=${imageTag.dynamodb()}",
      "DYNAMODB_PREFIX=${env.DYNAMODB_PREFIX}",
      "POSTGRES_IMAGE_TAG=${imageTag.postgres()}",
      "POSTGRES_PREFIX=${env.POSTGRES_PREFIX}",
      'POSTGRES_PASSWORD=sekret'
    ]) {
      sh """
        # Due to https://issues.jenkins.io/browse/JENKINS-15146, we have to set it to empty string here
        export CACHE_LOAD_SCOPE=\${CACHE_LOAD_SCOPE:-}
        export CACHE_SAVE_SCOPE=\${CACHE_SAVE_SCOPE:-}
        ./build/new-jenkins/run-migrations.sh
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $CASSANDRA_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $DYNAMODB_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push -a $POSTGRES_PREFIX || true
      """
    }

    archiveArtifacts(artifacts: 'migrate-*.log', allowEmptyArchive: true)
    sh 'docker-compose down --remove-orphans'
  }
}
