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
import instructure.FilesChangedDetector

// Singleton instance that persists across stages
@Field static FilesChangedDetector detector = null

// Get or create the singleton instance
def getDetector() {
  if (detector == null) {
    detector = new FilesChangedDetector()
  }
  return detector
}

// Reset the detector instance (call at the start of each pipeline run)
def reset() {
  detector = null
}

// Direct accessor methods
def hasBundleFiles() { return getDetector().hasBundleFiles() }
def hasDockerDevFiles() { return getDetector().hasDockerDevFiles() }
def hasGroovyFiles() { return getDetector().hasGroovyFiles() }
def hasSpecFiles() { return getDetector().hasSpecFiles() }
def hasYarnFiles() { return getDetector().hasYarnFiles() }
def hasGraphqlFiles() { return getDetector().hasGraphqlFiles() }
def hasErbFiles() { return getDetector().hasErbFiles() }
def hasJsFiles() { return getDetector().hasJsFiles() }

def preBuild() {
  def dockerDevFiles = [
    '^docker-compose/',
    '^script/common/',
    '^script/canvas_update',
    '^docker-compose.yml',
    '^Dockerfile$',
    '^lib/tasks/',
    'Jenkinsfile.docker-smoke'
  ]

  def d = getDetector()

  // Run independent git operations in parallel for better performance
  def parallelChecks = [:]

  parallelChecks['dockerDevFiles'] = {
    d.setDockerDevFiles(git.changedFiles(dockerDevFiles, 'HEAD^'))
  }

  parallelChecks['groovyFiles'] = {
    d.setGroovyFiles(git.changedFiles(['.*.groovy', 'Jenkinsfile.*'], 'HEAD^'))
  }

  parallelChecks['yarnFiles'] = {
    d.setYarnFiles(git.changedFiles(['package.json', 'yarn.lock'], 'HEAD^'))
  }

  parallelChecks['graphqlFiles'] = {
    d.setGraphqlFiles(git.changedFiles(['app/graphql', 'schema.graphql'], 'HEAD^'))
  }

  parallelChecks['erbFiles'] = {
    d.setErbFiles(git.changedFiles(['.erb'], 'HEAD^'))
  }

  parallelChecks['workdirChecks'] = {
    dir(env.LOCAL_WORKDIR) {
      d.setBundleFiles(sh(script: 'git diff --name-only HEAD^..HEAD | grep -E "Gemfile|gemspec"', returnStatus: true) == 0)
      d.setSpecFiles(sh(script: "${WORKSPACE}/build/new-jenkins/spec-changes.sh", returnStatus: true) == 0)
    }
  }

  // Execute all checks in parallel
  parallel parallelChecks

  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
  // https://issues.jenkins.io/browse/JENKINS-52750
  if (env.GERRIT_PROJECT != 'canvas-lms') {
    sh "rm -vrf $LOCAL_WORKDIR@tmp"
  }
}

def postBuild() {
  def d = getDetector()

  dir(env.LOCAL_WORKDIR) {
    d.setJsFiles(sh(script: "${WORKSPACE}/build/new-jenkins/js-changes.sh", returnStatus: true) == 0)
  }

  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
  // https://issues.jenkins.io/browse/JENKINS-52750
  if (env.GERRIT_PROJECT != 'canvas-lms') {
    sh "rm -vrf $LOCAL_WORKDIR@tmp"
  }
}
