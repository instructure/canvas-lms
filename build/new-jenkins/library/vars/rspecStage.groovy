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

  rspecNodeTotal.times { index ->
    extendedStage("RSpec Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .hooks([onNodeAcquired: setupNodeHook])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .queue(nestedStages) { unitStage(rspecNodeTotal, index) }
  }

  seleniumNodeTotal.times { index ->
    extendedStage("Selenium Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .hooks([onNodeAcquired: setupNodeHook])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .queue(nestedStages) { seleniumStage(seleniumNodeTotal, index) }
  }
}

def setupNode() {
  distribution.unstashBuildScripts()
}

def seleniumStage(seleniumNodeTotal, index) {
  rspec.runSeleniumSuite(seleniumNodeTotal, index)
}

def unitStage(rspecNodeTotal, index) {
  rspec.runRSpecSuite(rspecNodeTotal, index)
}
