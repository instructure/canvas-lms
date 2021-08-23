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

@Field final static STAGE_NAME = 'Detect Files Changed'

def hasDockerDevFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('dockerDevFiles')
}

def hasFeatureFlagFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('featureFlagFiles')
}

def hasGroovyFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('groovyFiles')
}

def hasMigrationFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('migrationFiles')
}

def hasSpecFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('specFiles')
}

def hasYarnFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('yarnFiles')
}

def call(stageConfig) {
  def dockerDevFiles = [
    '^docker-compose/',
    '^script/common/',
    '^script/canvas_update',
    '^docker-compose.yml',
    '^Dockerfile$',
    '^lib/tasks/',
    'Jenkinsfile.docker-smoke'
  ]

  stageConfig.value('dockerDevFiles', git.changedFiles(dockerDevFiles, 'HEAD^'))
  stageConfig.value('featureFlagFiles', git.changedFiles(['config/feature_flags'], 'HEAD^'))
  stageConfig.value('groovyFiles', git.changedFiles(['.*.groovy', 'Jenkinsfile.*'], 'HEAD^'))
  stageConfig.value('yarnFiles', git.changedFiles(['package.json', 'yarn.lock'], 'HEAD^'))
  stageConfig.value('migrationFiles', sh(script: 'build/new-jenkins/check-for-migrations.sh', returnStatus: true) == 0)

  dir(env.LOCAL_WORKDIR) {
    stageConfig.value('specFiles', sh(script: "${WORKSPACE}/build/new-jenkins/spec-changes.sh", returnStatus: true) == 0)
  }

  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
  // https://issues.jenkins.io/browse/JENKINS-52750
  if (env.GERRIT_PROJECT != 'canvas-lms') {
    sh "rm -vrf $LOCAL_WORKDIR@tmp"
  }

  distribution.stashBuildScripts()
}
