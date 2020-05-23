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

// TODO: until we get this into a shared library,
//       i dont think we can hold flags in a variable

// TODO: maybe add a set of allowed flags so we know if we fat-finger something?

def hasFlag(name) {
  def script = """#!/bin/sh
    set -e
    message=`echo "\$GERRIT_CHANGE_COMMIT_MESSAGE" | base64 --decode`
    if echo "\$message" | grep -Eq '\\[$name\\]' ; then
      echo "found"
    fi
  """
  def result = sh(
    script: script,
    returnStdout: true
  ).trim() == 'found'
  echo "hasFlag($name) => $result"
  return result
}

def getImageTagVersion() {
  // 'refs/changes/63/181863/8' -> '63.181863.8'
  return "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
}

def forceRunCoverage() {
  return hasFlag('force-run-coverage')
}

def isForceFailure() {
  return hasFlag('force-failure')
}

def isForceFailureJS() {
  return isForceFailure() || hasFlag('force-failure-js')
}

def isForceFailureRspec() {
  return isForceFailure() || hasFlag('force-failure-rspec')
}

def isForceFailureSelenium() {
  return isForceFailure() || hasFlag('force-failure-selenium')
}

def isForceFailureFSC() {
  return isForceFailure() || hasFlag('force-failure-fsc')
}

return this
