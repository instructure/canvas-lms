/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import groovy.time.*

/**
 * appends stages to the nodes based on the count passed into
 * the closure.
 *
 * @nodes: the hash of nodes to be ran later
 * @stageCount: the amount of nodes to add to the hash
 * @stageNamePrefix: the name to prefix the stages with
 * @testLabel: specific test label used to mark the success and identify node pool. null/false if no marking.
 * @stageBlock: the closure thats exectued after unstashing build scripts
 */
def appendStagesAsBuildNodes(nodes,
                             stageCount,
                             stageNamePrefix,
                             testLabel,
                             stageBlock) {
  for (int i = 0; i < stageCount; i++) {
    // make this a local variable so when the closure resolves
    // it gets the correct number
    def index = i
    // we cant use String.format, so... yea
    def stageName = "$stageNamePrefix ${(index + 1).toString().padLeft(2, '0')}"
    def timeStart = new Date()
    extendedStage(stageName).nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker').queue(nodes) {
      echo "Running on node ${env.NODE_NAME}"

      unstashBuildScripts()
      stageBlock(index)
    }
  }
}

def stashBuildScripts() {
  stash name: 'build-dir', includes: 'build/**/*'
  stash name: 'build-docker-compose', includes: 'docker-compose.*.yml'
}

def unstashBuildScripts() {
  unstash name: 'build-dir'
  unstash name: 'build-docker-compose'
}

/**
 * common helper for adding rspec tests to be ran
 */
def addRSpecSuites(stages) {
  def rspecNodeTotal = rspec.rspecConfig().node_total
  echo 'adding RSpec Test Sets'
  appendStagesAsBuildNodes(stages, rspecNodeTotal, 'RSpec Test Set', 'rspec') { index ->
    rspec.runRSpecSuite(rspecNodeTotal, index)
  }
}

/**
 * common helper for adding selenium tests to be ran
 */
def addSeleniumSuites(stages) {
  def seleniumNodeTotal = rspec.seleniumConfig().node_total
  echo 'adding Selenium Test Sets'
  appendStagesAsBuildNodes(stages, seleniumNodeTotal, 'Selenium Test Set', 'selenium') { index ->
    rspec.runSeleniumSuite(seleniumNodeTotal, index)
  }
}

return this
