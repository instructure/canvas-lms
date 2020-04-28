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

def log(message) {
  echo "[successes.groovy]: ${message}"
}

def successFile() {
  return "_buildmeta/${env.GERRIT_CHANGE_NUMBER}-${env.GERRIT_PATCHSET_NUMBER}-successes"
}

// we have a stage that marks a build as successful. this removes
// all success marks and replaces it with the 'build' mark. this
// causes the post hooks to be unable to read successes.
def hasSuccessOrBuildIsSuccessful(name, required_count = 1) {
  return hasSuccess('build') || hasSuccess(name, required_count)
}

def hasSuccess(name, required_count = 1) {
  if (!fileExists(successFile())) {
    copyArtifacts(
      filter: '_buildmeta/*',
      optional: true,
      projectName: env.JOB_NAME,
      parameters: "GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER},GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER}",
      selector: lastCompleted()
    )
    archiveArtifacts(artifacts: '_buildmeta/*', allowEmptyArchive: true)
  }
  def result = false
  if (fileExists(successFile())) {
    // read the file and split for lines
    def lines = readFile(successFile()).split('\n')
    // count how many times the success has been marked
    def count = lines.count { it == "|$name|" }
    // check if the required amount of successes have happened
    result = required_count <= count
  }
  return result
}

def clearSuccesses(name) {
  if (hasSuccess(name)) {
    // read all the lines from the success file
    def lines = readFile(successFile()).split('\n')
    // filter all of the successes we dont want
    def keeping = lines.findAll { it != "|$name|" }
    // save the new success file
    sh "rm ${successFile()}"
    sh "echo '${keeping.join('\n')}' >> ${successFile()}"
    archiveArtifacts(artifacts: '_buildmeta/*')
  }
}

def saveSuccess(name) {
  sh 'mkdir -p _buildmeta'
  sh "echo '|$name|' >> ${successFile()}"
  archiveArtifacts(artifacts: '_buildmeta/*')
  log "Success artifact created, future builds will skip this step $name: ${successFile()}"
  sh "cat ${successFile()}"
}

// runs the body if it has not previously succeeded.
// if you don't want the success of the body to mark the
// given name as successful, pass in save = false.
def skipIfPreviouslySuccessful(name, save = true, body) {
  def flags = load 'build/new-jenkins/groovy/commit-flags.groovy'
  cacheEnabled = !flags.hasFlag('skip-cache')

  if (hasSuccess(name) && cacheEnabled) {
    log "Block already successful, skipping: ${successFile()}"
  } else {
    if (cacheEnabled) {
      log 'Build was not previously successful, executing underlying code.'
    } else {
      log 'Build cache is disabled! Executing all underlying code and ignoring previous build successes.'
    }
    body.call()
    if (save) saveSuccess(name)
  }
}

def markBuildAsSuccessful() {
  sh "rm -f ${successFile()}"
  saveSuccess('build')
}

return this
