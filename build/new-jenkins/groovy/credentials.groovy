


def withGerritCredentials(block) {
  withCredentials([
    sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')
  ]) { block.call() }
}

def fetchFromGerrit(String repo, String path, String customRepoDestination = null, String sourcePath = null, String sourceRef = null) {
  withGerritCredentials({ ->
    println "Fetching ${repo} plugin"
    sh """
      mkdir -p ${path}/${customRepoDestination ?: repo}
      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
        git archive --remote=ssh://$GERRIT_URL/${repo} ${sourceRef == null ? 'master' : sourceRef} ${sourcePath == null ? '' : sourcePath} | tar -x -C ${path}/${customRepoDestination ?: repo}
    """
  })
}

return this