def call() {
  credentials.withStarlordCredentials {
    def cacheLoadScope = configuration.isChangeMerged() || configuration.getBoolean('skip-cache') ? '' : env.IMAGE_CACHE_MERGE_SCOPE
    def cacheSaveScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : ''

    withEnv([
      "CACHE_LOAD_SCOPE=${cacheLoadScope}",
      "CACHE_SAVE_SCOPE=${cacheSaveScope}",
      "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
      "CASSANDRA_IMAGE_TAG=${imageTag.cassandra()}",
      "CASSANDRA_PREFIX=${env.CASSANDRA_PREFIX}",
      "COMPOSE_FILE=docker-compose.new-jenkins.yml",
      "DYNAMODB_IMAGE_TAG=${imageTag.dynamodb()}",
      "DYNAMODB_PREFIX=${env.DYNAMODB_PREFIX}",
      "POSTGRES_IMAGE_TAG=${imageTag.postgres()}",
      "POSTGRES_PREFIX=${env.POSTGRES_PREFIX}",
      "POSTGRES_PASSWORD=sekret"
    ]) {
      sh """
        # Due to https://issues.jenkins.io/browse/JENKINS-15146, we have to set it to empty string here
        export CACHE_LOAD_SCOPE=\${CACHE_LOAD_SCOPE:-}
        export CACHE_SAVE_SCOPE=\${CACHE_SAVE_SCOPE:-}
        ./build/new-jenkins/run-migrations.sh
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $CASSANDRA_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $DYNAMODB_PREFIX || true
        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $POSTGRES_PREFIX || true
      """
    }

    archiveArtifacts(artifacts: "migrate-*.log", allowEmptyArchive: true)
    sh 'docker-compose down --remove-orphans'
  }
}
