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

import groovy.transform.Field

@Field static dockerVolumeName = "gergich-results-${System.currentTimeMillis()}"

def _getDockerInputs() {
  def inputVars = [
    '--env GERGICH_DB_PATH=/home/docker/gergich',
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

  if (env.GERRIT_PROJECT != 'canvas-lms') {
    inputVars.addAll([
      "--env GERGICH_GIT_PATH=/usr/src/app/gems/plugins/$GERRIT_PROJECT",
    ])
  }

  return inputVars.join(' ')
}

def setupNode() {
  distribution.unstashBuildScripts()

  sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $LINTERS_RUNNER_IMAGE'
  sh "docker volume create $dockerVolumeName"
}

def tearDownNode() {
  withEnv([
    "DOCKER_INPUTS=${_getDockerInputs()}",
    "GERGICH_VOLUME=$dockerVolumeName",
  ]) {
    sh './build/new-jenkins/linters/run-gergich-publish.sh'
  }
}

def codeStage() {
  withEnv([
    "DOCKER_INPUTS=${_getDockerInputs()}",
    "GERGICH_VOLUME=$dockerVolumeName",
    "SKIP_ESLINT=${configuration.getBoolean('skip-eslint', 'false')}",
  ]) {
    sh './build/new-jenkins/linters/run-gergich-linters.sh'
  }

  if (configuration.getBoolean('force-failure-linters', 'false')) {
    error 'lintersStage: force failing due to flag'
  }
}

def dependencyCheckStage() {
  catchError (buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
    try {
      snyk('canvas-lms:ruby', 'Gemfile.lock', "$LINTERS_RUNNER_IMAGE")
    }
    catch (err) {
      if (err.toString().contains('Gemfile.lock does not exist')) {
        snyk('canvas-lms:ruby', 'Gemfile.lock.next', "$LINTERS_RUNNER_IMAGE")
      } else {
        throw err
      }
    }
  }
}

def masterBouncerStage() {
  credentials.withMasterBouncerCredentials {
    sh 'build/new-jenkins/linters/run-master-bouncer.sh'
  }
}

def webpackStage() {
  withEnv([
    "DOCKER_INPUTS=${_getDockerInputs()}",
    "GERGICH_VOLUME=$dockerVolumeName",
  ]) {
    sh './build/new-jenkins/linters/run-gergich-webpack.sh'
  }

  if (configuration.getBoolean('force-failure-linters', 'false')) {
    error 'lintersStage: force failing due to flag'
  }
}

def yarnStage() {
  withEnv([
    "DOCKER_INPUTS=${_getDockerInputs()}",
    "GERGICH_VOLUME=$dockerVolumeName",
    "PLUGINS_LIST=${configuration.plugins().join(' ')}",
  ]) {
    sh './build/new-jenkins/linters/run-gergich-yarn.sh'
  }

  if (configuration.getBoolean('force-failure-linters', 'false')) {
    error 'lintersStage: force failing due to flag'
  }
}

def groovyStage() {
  sh '''docker run $LINTERS_RUNNER_IMAGE \
    npx npm-groovy-lint --path "./build/new-jenkins/library/" \
    --files "**/*.groovy" --config ".groovylintrc.json"  \
    --loglevel info --failon info'''
}
