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

def withGerritCredentials(block) {
  withCredentials([
    sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')
  ]) { block.call() }
}

def withMasterBouncerCredentials(block) {
  withCredentials([
    string(credentialsId: 'master-bouncer-key', variable: 'MASTER_BOUNCER_KEY')
  ]) { block.call() }
}

def fetchFromGerrit(String repo, String path, String customRepoDestination = null, String sourcePath = null, String sourceRef = null) {
  withGerritCredentials({ ->
    println "Fetching ${repo} plugin"
    sh """
      mkdir -p ${path}/${customRepoDestination ?: repo}
      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
        git archive --remote=ssh://$GERRIT_URL/${repo} ${sourceRef == null ? 'master' : sourceRef} ${sourcePath == null ? '' : sourcePath} | tar -x -v -C ${path}/${customRepoDestination ?: repo}
    """
  })
}

return this
