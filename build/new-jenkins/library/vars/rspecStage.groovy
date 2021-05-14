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

def createDistribution(nestedStages) {
  def rspecNodeTotal = configuration.getInteger('rspec-ci-node-total')
  def seleniumNodeTotal = configuration.getInteger('selenium-ci-node-total')
  def setupNodeHook = this.&setupNode

  def baseEnvVars = [
    "ENABLE_AXE_SELENIUM=${env.ENABLE_AXE_SELENIUM}",
    'POSTGRES_PASSWORD=sekret',
    "SELENIUM_VERSION=3.141.59-20201119",
  ]

  def rspecEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$rspecNodeTotal",
    "COMPOSE_FILE=docker-compose.new-jenkins.yml",
    "EXCLUDE_TESTS=.*/(selenium|contracts)",
    "FORCE_FAILURE=${configuration.isForceFailureRSpec() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('rspec-rerun-retry')}",
    "RSPEC_PROCESSES=4",
    "TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/",
  ]

  def seleniumEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$seleniumNodeTotal",
    "COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml",
    "EXCLUDE_TESTS=.*/performance",
    "FORCE_FAILURE=${configuration.isForceFailureSelenium() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('selenium-rerun-retry')}",
    "RSPEC_PROCESSES=3",
    "TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/selenium",
  ]

  rspecNodeTotal.times { index ->
    extendedStage("RSpec Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .envVars(rspecEnvVars + ["CI_NODE_INDEX=$index"])
      .hooks([onNodeAcquired: setupNodeHook])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .queue(nestedStages) { rspec.runSuite('rspec') }
  }

  seleniumNodeTotal.times { index ->
    extendedStage("Selenium Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .envVars(seleniumEnvVars + ["CI_NODE_INDEX=$index"])
      .hooks([onNodeAcquired: setupNodeHook])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .queue(nestedStages) { rspec.runSuite('selenium') }
    }
}

def setupNode() {
  distribution.unstashBuildScripts()
}
