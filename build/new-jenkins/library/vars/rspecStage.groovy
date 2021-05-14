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
    'SELENIUM_VERSION=3.141.59-20201119',
  ]

  def rspecEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$rspecNodeTotal",
    'COMPOSE_FILE=docker-compose.new-jenkins.yml',
    'EXCLUDE_TESTS=.*/(selenium|contracts)',
    "FORCE_FAILURE=${configuration.isForceFailureRSpec() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('rspec-rerun-retry')}",
    'RSPEC_PROCESSES=4',
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/',
  ]

  def seleniumEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$seleniumNodeTotal",
    'COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
    'EXCLUDE_TESTS=.*/performance',
    "FORCE_FAILURE=${configuration.isForceFailureSelenium() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('selenium-rerun-retry')}",
    'RSPEC_PROCESSES=3',
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/selenium',
  ]

  rspecNodeTotal.times { index ->
    extendedStage("RSpec Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .envVars(rspecEnvVars + ["CI_NODE_INDEX=$index"])
      .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('rspec') }])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .timeout(15)
      .queue(nestedStages) { rspec.runSuite() }
  }

  seleniumNodeTotal.times { index ->
    extendedStage("Selenium Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .envVars(seleniumEnvVars + ["CI_NODE_INDEX=$index"])
      .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('selenium') }])
      .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
      .timeout(15)
      .queue(nestedStages) { rspec.runSuite() }
    }
}

def setupNode() {
  distribution.unstashBuildScripts()

  credentials.withStarlordDockerLogin { ->
    sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
  }

  sh(script: 'build/new-jenkins/docker-compose-build-up.sh', label: 'Start Containers')
}

def tearDownNode(prefix) {
  sh 'rm -rf ./tmp && mkdir -p tmp'
  sh "build/new-jenkins/docker-copy-files.sh /usr/src/app/log/spec_failures/ tmp/spec_failures/$prefix canvas_ --allow-error --clean-dir"
  sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results tmp/rspec_results canvas_ --allow-error --clean-dir'

  if (configuration.getBoolean('upload-docker-logs', 'false')) {
    sh "docker ps -aq | xargs -I{} -n1 -P1 docker logs --timestamps --details {} 2>&1 > tmp/docker-${prefix}-${env.CI_NODE_INDEX}.log"
    archiveArtifacts(artifacts: "tmp/docker-${prefix}-${env.CI_NODE_INDEX}.log")
  }

  archiveArtifacts allowEmptyArchive: true, artifacts: "tmp/spec_failures/$prefix/**/*"
  findFiles(glob: "tmp/spec_failures/$prefix/**/index.html").each { file ->
    // node_18/spec_failures/canvas__9224fba6fc34/spec_failures/Initial/spec/selenium/force_failure_spec.rb:20/index
    // split on the 5th to give us the rerun category (Initial, Rerun_1, Rerun_2...)

    def pathCategory = file.getPath().split('/')[5]
    def finalCategory = reruns_retry.toInteger() == 0 ? 'Initial' : "Rerun_${reruns_retry.toInteger()}"
    def splitPath = file.getPath().split('/').toList()
    def specTitle = splitPath.subList(6, splitPath.size() - 1).join('/')
    def artifactsPath = "../artifact/${file.getPath()}"

    buildSummaryReport.addFailurePath(specTitle, artifactsPath, pathCategory)

    if (pathCategory == finalCategory) {
      buildSummaryReport.setFailureCategory(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_NEVER_PASSED)
    } else {
      buildSummaryReport.setFailureCategoryUnlessExists(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_PASSED_ON_RETRY)
    }
  }

  // junit publishing will set build status to unstable if failed tests found, if so set it back to the original value
  def preStatus = currentBuild.rawBuild.@result

  junit allowEmptyResults: true, testResults: 'tmp/rspec_results/**/*.xml'

  if (currentBuild.getResult() == 'UNSTABLE' && preStatus != 'UNSTABLE') {
    currentBuild.rawBuild.@result = preStatus
  }

  if (env.RSPEC_LOG == '1') {
    sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/parallel_runtime/ ./tmp/parallel_runtime_rspec_tests canvas_ --allow-error --clean-dir'
    archiveArtifacts(artifacts: 'tmp/parallel_runtime_rspec_tests/**/*.log')
  }

  sh 'rm -rf ./tmp'
}
