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

/**
 * appends stages to the nodes based on the count passed into
 * the closure.
 *
 * @nodes: the hash of nodes to be ran later
 * @stage_count: the amount of nodes to add to the hash
 * @stage_name_prefix: the name to prefix the stages with
 * @stage_block: the closure thats exectued after unstashing build scripts
 */
def appendStagesAsBuildNodes(nodes,
                             stage_count,
                             stage_name_prefix,
                             stage_block) {
  for(int i = 0; i < stage_count; i++) {
    // make this a local variable so when the closure resolves
    // it gets the correct number
    def index = i;
    // we cant use String.format, so... yea
    def stage_name = "$stage_name_prefix ${index + 1}"
    nodes[stage_name] = {
      node('canvas-docker') {
        stage(stage_name) {
          // make sure to unstash
          unstash name: "build-dir"
          unstash name: "build-docker-compose"
          stage_block(index)
        }
      }
    }
  }
}

/**
 * use this in combination with appendStagesAsBuildNodes. this will
 * stash the required files for running biulds that only require
 * the build scripts
 */
def stashBuildScripts() {
  stash name: "build-dir", includes: 'build/**/*'
  stash name: "build-docker-compose", includes: 'docker-compose.*.yml'
}

/**
 * common helper for adding both rspec and selenium tests to be ran
 */
def addRSpecSuites(stages) {
  def rspec_config = load('build/new-jenkins/groovy/rspec.groovy').config()
  def selenium_node_total = rspec_config.selenium_node_total
  def rspec_node_total = rspec_config.rspec_node_total

  echo 'adding Selenium Test Sets'
  appendStagesAsBuildNodes(stages, selenium_node_total, "Selenium Test Set") { index ->
    load('build/new-jenkins/groovy/rspec.groovy').runSeleniumSuite(selenium_node_total, index)
  }

  echo 'adding RSpec Test Sets'
  appendStagesAsBuildNodes(stages, rspec_node_total, "RSpec Test Set") { index ->
    load('build/new-jenkins/groovy/rspec.groovy').runRSpecSuite(rspec_node_total, index)
  }
}

return this