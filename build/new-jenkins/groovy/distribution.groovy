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
 * @stage_count: the amount of nodes to add to the hash
 * @stage_name_prefix: the name to prefix the stages with
 * @test_label: specific test label used to mark the success and identify node pool. null/false if no marking.
 * @stage_block: the closure thats exectued after unstashing build scripts
 */
def appendStagesAsBuildNodes(nodes,
                             stage_count,
                             stage_name_prefix,
                             test_label,
                             stage_block) {
  for(int i = 0; i < stage_count; i++) {
    // make this a local variable so when the closure resolves
    // it gets the correct number
    def index = i;
    // we cant use String.format, so... yea
    def stage_name = "$stage_name_prefix ${(index + 1).toString().padLeft(2, '0')}"
    def timeStart = new Date()
    nodes[stage_name] = {
      protectedNode("canvas-$test_label-docker") {
        def duration = TimeCategory.minus(new Date(), timeStart).toMilliseconds()
        // make sure to unstash
        unstash name: "build-dir"
        unstash name: "build-docker-compose"
        stage_block(index)
      }

      // mark with instance index.
      // we need to do this on the main node so we dont run into
      // concurrency issues with persisting the success
      load('build/new-jenkins/groovy/successes.groovy').saveSuccess(test_label)
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
 * common helper for adding rspec tests to be ran
 */
def addRSpecSuites(stages) {
  def rspec_node_total = load('build/new-jenkins/groovy/rspec.groovy').rspecConfig().node_total
  def successes = load('build/new-jenkins/groovy/successes.groovy')

  if (successes.hasSuccess('rspec', rspec_node_total)) {
    echo 'not running rspec. already successful'
  }
  else {
    echo 'adding RSpec Test Sets'
    successes.clearSuccesses('rspec')
    appendStagesAsBuildNodes(stages, rspec_node_total, 'RSpec Test Set', 'rspec') { index ->
      load('build/new-jenkins/groovy/rspec.groovy').runRSpecSuite(rspec_node_total, index)
    }
  }
}

/**
 * common helper for adding selenium tests to be ran
 */
def addSeleniumSuites(stages) {
  def selenium_node_total = load('build/new-jenkins/groovy/rspec.groovy').seleniumConfig().node_total
  def successes = load('build/new-jenkins/groovy/successes.groovy')

  if (successes.hasSuccess('selenium', selenium_node_total)) {
    echo 'not running selenium. already successful'
  }
  else {
    echo 'adding Selenium Test Sets'
    successes.clearSuccesses('selenium')
    appendStagesAsBuildNodes(stages, selenium_node_total, 'Selenium Test Set', 'selenium') { index ->
      load('build/new-jenkins/groovy/rspec.groovy').runSeleniumSuite(selenium_node_total, index)
    }
  }
}

return this
