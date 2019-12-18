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

def fullSuccessName(name) {
  return "_successes/${env.GERRIT_CHANGE_NUMBER}-${env.GERRIT_PATCHSET_NUMBER}-${name}-success"
}

def hasSuccess(name) {
  copyArtifacts(filter: "_successes/*",
                optional: true,
                projectName: '/${JOB_NAME}',
                parameters: "GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER},GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER}",
                selector: lastCompleted())
  if (fileExists("_successes")) {
    archiveArtifacts(artifacts: "_successes/*",
                    projectName: '/${JOB_NAME}')
  }
  return fileExists(fullSuccessName(name))
}

def saveSuccess(name) {
  def success_name = fullSuccessName(name)
  sh "mkdir -p _successes"
  sh "echo 'success' >> ${success_name}"
  archiveArtifacts(artifacts: "_successes/*",
                   projectName: '/${JOB_NAME}')
  echo "===> success saved /${env.JOB_NAME}: ${success_name}"
}

// runs the body if it has not previously succeeded.
// if you don't want the success of the body to mark the
// given name as successful, pass in save = false.
def skipIfPreviouslySuccessful(name, save = true, body) {
  if (hasSuccess(name)) {
    echo "===> block already successful, skipping: ${fullSuccessName(name)}"
  } else {
    echo "===> running block: ${fullSuccessName(name)}"
    body.call()
    if (save) saveSuccess(name)
  }
}

return this
