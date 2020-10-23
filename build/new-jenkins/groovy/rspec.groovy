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

def seleniumConfig() {
  [
    node_total: configuration.getInteger('selenium-ci-node-total'),
    max_fail: configuration.getInteger('selenium-max-fail'),
    reruns_retry: configuration.getInteger('selenium-rerun-retry'),
    force_failure: configuration.isForceFailureSelenium() ? "1" : '',
    patchsetTag: env.PATCHSET_TAG,
  ]
}

def runSeleniumSuite(total, index) {
  def config = seleniumConfig()
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
      'selenium',
      config.max_fail,
      config.reruns_retry,
      '^./(spec|gems/plugins/.*/spec_canvas)/selenium',
      '.*/performance',
      '3',
      config.force_failure,
      config.patchsetTag
  )
}

def rspecConfig() {
  [
    node_total: configuration.getInteger('rspec-ci-node-total'),
    max_fail: configuration.getInteger('rspec-max-fail'),
    reruns_retry: configuration.getInteger('rspec-rerun-retry'),
    force_failure: configuration.isForceFailureRSpec() ? "1" : '',
    patchsetTag: env.PATCHSET_TAG,
  ]
}

def runRSpecSuite(total, index) {
  def config = rspecConfig()
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.yml',
      'rspec',
      config.max_fail,
      config.reruns_retry,
      '^./(spec|gems/plugins/.*/spec_canvas)/',
      '.*/selenium',
      '4',
      config.force_failure,
      config.patchsetTag
  )
}

def _runRspecTestSuite(
    total,
    index,
    compose,
    prefix,
    max_fail,
    reruns_retry,
    test_file_pattern,
    exclude_regex,
    docker_processes,
    force_failure,
    patchsetTag
) {
  withEnv([
      "CI_NODE_INDEX=$index",
      "COMPOSE_FILE=$compose",
      "RERUNS_RETRY=$reruns_retry",
      "MAX_FAIL=$max_fail",
      "TEST_PATTERN=$test_file_pattern",
      "EXCLUDE_TESTS=$exclude_regex",
      "CI_NODE_TOTAL=$total",
      "DOCKER_PROCESSES=$docker_processes",
      "FORCE_FAILURE=$force_failure",
      "POSTGRES_PASSWORD=sekret",
      "SELENIUM_VERSION=3.141.59-20200719",
      "PATCHSET_TAG=$patchsetTag",
  ]) {
    try {
      cleanAndSetup()
      sh 'rm -rf ./tmp'
      sh 'mkdir -p tmp'
      timeout(time: 60) {
        sh 'build/new-jenkins/docker-compose-pull.sh'

        if(prefix == 'selenium') {
          sh 'build/new-jenkins/docker-compose-pull-selenium.sh'
        }

        sh 'build/new-jenkins/docker-compose-build-up.sh'
        sh 'build/new-jenkins/docker-compose-rspec-parallel.sh'
      }
    } catch(Exception e) {
      failureReport.addFailure(prefix, "${BUILD_URL}${prefix}-test-failures")

      throw e
    } finally {
      // copy spec failures to local
      sh "build/new-jenkins/docker-copy-files.sh /usr/src/app/log/spec_failures/ tmp/spec_failures/$prefix canvas_ --allow-error --clean-dir"
      sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results.xml tmp/rspec_results canvas_ --allow-error --clean-dir'

      archiveArtifacts allowEmptyArchive: true, artifacts: "tmp/spec_failures/$prefix/**/*"

      // junit publishing will set build status to unstable if failed tests found, if so set it back to the original value
      def preStatus = currentBuild.rawBuild.@result

      junit allowEmptyResults: true, testResults: "tmp/rspec_results/**/*.xml"

      if(currentBuild.getResult() == 'UNSTABLE' && preStatus != 'UNSTABLE') {
        currentBuild.rawBuild.@result = preStatus
      }

      def reports = load 'build/new-jenkins/groovy/reports.groovy'

      if (env.COVERAGE == '1') {
        sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/coverage/ tmp/spec_coverage canvas_ --clean-dir'
        reports.stashSpecCoverage(prefix, index)
      }

      if (env.RSPEC_LOG == '1') {
        sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/parallel_runtime_rspec_tests.log ./tmp/parallel_runtime_rspec_tests canvas_ --allow-error --clean-dir'
        reports.stashParallelLogs(prefix, index)
      }

      sh 'rm -rf ./tmp'
      execute 'bash/docker-cleanup.sh --allow-failure'
    }
  }
}

def uploadSeleniumCoverageIfSuccessful() {
  _uploadCoverageIfSuccessful('selenium', seleniumConfig().node_total, 'canvas-lms-selenium')
}

def uploadRSpecCoverageIfSuccessful() {
  _uploadCoverageIfSuccessful('rspec', rspecConfig().node_total, 'canvas-lms-rspec')
}

def _uploadCoverageIfSuccessful(prefix, total, coverage_name) {
  if (successes.hasSuccess(prefix, total)) {
    def reports = load 'build/new-jenkins/groovy/reports.groovy'
    reports.publishSpecCoverageToS3(prefix, total, coverage_name)
  }
}

def uploadParallelLog() {
  def reports = load('build/new-jenkins/groovy/reports.groovy')
  reports.copyParallelLogs(rspecConfig().node_total, seleniumConfig().node_total)
  archiveArtifacts(artifacts: "parallel_logs/**")
}

return this
