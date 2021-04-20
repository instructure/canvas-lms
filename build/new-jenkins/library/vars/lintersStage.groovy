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

def _getDockerInputs() {
  def inputVars = [
    "--volume $WORKSPACE/.git:/usr/src/app/.git",
    "--env GERGICH_DB_PATH=/home/docker/gergich",
    "--env GERGICH_PUBLISH=$GERGICH_PUBLISH",
    "--env GERGICH_KEY=$GERGICH_KEY",
    "--env GERRIT_HOST=$GERRIT_HOST",
    "--env GERRIT_PROJECT=$GERRIT_PROJECT",
    "--env GERRIT_BRANCH=$GERRIT_BRANCH",
    "--env GERRIT_EVENT_ACCOUNT_EMAIL=$GERRIT_EVENT_ACCOUNT_EMAIL",
    "--env GERRIT_PATCHSET_NUMBER=$GERRIT_PATCHSET_NUMBER",
    "--env GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION",
    "--env GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID",
    "--env GERRIT_CHANGE_NUMBER=$GERRIT_CHANGE_NUMBER",
    "--env GERRIT_REFSPEC=$GERRIT_REFSPEC",
  ]

  if(env.GERRIT_PROJECT != "canvas-lms") {
    inputVars.addAll([
      "--volume $WORKSPACE/gems/plugins/$GERRIT_PROJECT/.git:/usr/src/app/gems/plugins/$GERRIT_PROJECT/.git",
      "--env GERGICH_GIT_PATH=/usr/src/app/gems/plugins/$GERRIT_PROJECT",
    ])
  }

  return inputVars.join(' ')
}

def call() {
  credentials.withStarlordCredentials {
    sh "./build/new-jenkins/linters/docker-build.sh local/gergich"

    if(configuration.getBoolean('upload-linter-debug-image', 'false')) {
      sh """
      docker tag local/gergich $LINTER_DEBUG_IMAGE
      docker push $LINTER_DEBUG_IMAGE
      """
    }

    credentials.withGerritCredentials {
      withEnv([
        "DOCKER_INPUTS=${_getDockerInputs()}",
        "FORCE_FAILURE=${configuration.getBoolean('force-failure-linters', 'false')}",
        "GERGICH_VOLUME=gergich-results-${System.currentTimeMillis()}",
        "PLUGINS_LIST=${configuration.plugins().join(' ')}",
        "SKIP_ESLINT=${configuration.getString('skip-eslint', 'false')}",
      ]) {
        sh 'build/new-jenkins/linters/run-gergich.sh'
      }
    }
    if (env.MASTER_BOUNCER_RUN == '1' && !configuration.isChangeMerged()) {
      credentials.withMasterBouncerCredentials {
        sh 'build/new-jenkins/linters/run-master-bouncer.sh'
      }
    }
  }
}
