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

@Field final static STAGE_NAME = 'Detect Files Changed (Pre-Build)'
@Field final static STAGE_NAME_POST_BUILD = 'Detect Files Changed (Post-Build)'

def hasBundleFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('bundleFiles')
}

def hasDockerDevFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('dockerDevFiles')
}

def hasGroovyFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('groovyFiles')
}

def hasSpecFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('specFiles')
}

def hasYarnFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('yarnFiles')
}

def hasGraphqlFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('graphqlFiles')
}

def hasJsFiles(buildConfig) {
  return buildConfig[STAGE_NAME_POST_BUILD].value('jsFiles')
}

def hasNewDeletedSpecFiles(buildConfig) {
  return buildConfig[STAGE_NAME].value('addedOrDeletedSpecFiles')
}

def preBuild(stageConfig) {
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
  stageConfig.value('graphqlFiles', git.changedFiles(['app/graphql'], 'HEAD^'))
  stageConfig.value('addedOrDeletedSpecFiles', sh(script: 'git diff --name-only --diff-filter=AD HEAD^..HEAD | grep "_spec.rb"', returnStatus: true) == 0)

  dir(env.LOCAL_WORKDIR) {
    stageConfig.value('bundleFiles', sh(script: 'git diff --name-only HEAD^..HEAD | grep -E "Gemfile|gemspec"', returnStatus: true) == 0)
    stageConfig.value('specFiles', sh(script: "${WORKSPACE}/build/new-jenkins/spec-changes.sh", returnStatus: true) == 0)
  }

  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
  // https://issues.jenkins.io/browse/JENKINS-52750
  if (env.GERRIT_PROJECT != 'canvas-lms') {
    sh "rm -vrf $LOCAL_WORKDIR@tmp"
  }
}

def postBuild(stageConfig) {
  dir(env.LOCAL_WORKDIR) {
    stageConfig.value('jsFiles', sh(script: "${WORKSPACE}/build/new-jenkins/js-changes.sh", returnStatus: true) == 0)
  }

  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
  // https://issues.jenkins.io/browse/JENKINS-52750
  if (env.GERRIT_PROJECT != 'canvas-lms') {
    sh "rm -vrf $LOCAL_WORKDIR@tmp"
  }
}
