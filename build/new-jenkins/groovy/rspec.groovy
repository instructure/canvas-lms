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
    force_failure: configuration.isForceFailureSelenium() ? "1" : ''
  ]
}

def runSeleniumSuite(total, index) {
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.multiple-processes.yml:docker-compose.new-jenkins-selenium.yml',
      'selenium',
      seleniumConfig().max_fail,
      seleniumConfig().reruns_retry,
      '^./(spec|gems/plugins/.*/spec_canvas)/selenium',
      '.*/performance',
      '3',
      seleniumConfig().force_failure
  )
}

def rspecConfig() {
  [
    node_total: configuration.getInteger('rspec-ci-node-total'),
    max_fail: configuration.getInteger('rspec-max-fail'),
    reruns_retry: configuration.getInteger('rspec-rerun-retry'),
    force_failure: configuration.isForceFailureRSpec() ? "1" : ''
  ]
}

def runRSpecSuite(total, index) {
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.multiple-processes.yml',
      'rspec',
      rspecConfig().max_fail,
      rspecConfig().reruns_retry,
      '^./(spec|gems/plugins/.*/spec_canvas)/',
      '.*/selenium',
      '4',
      rspecConfig().force_failure
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
    force_failure) {
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
  ]) {
    try {
      cleanAndSetup()
      sh 'rm -rf ./tmp'
      sh 'mkdir -p tmp'
      timeout(time: 60) {
        sh 'build/new-jenkins/docker-compose-pull.sh'
        sh 'build/new-jenkins/docker-compose-pull-selenium.sh'
        sh 'build/new-jenkins/docker-compose-build-up.sh'
        sh 'build/new-jenkins/docker-compose-setup-databases.sh'
        sh 'build/new-jenkins/rspec_parallel_dockers.sh'
      }
    }
    finally {
      // copy spec failures to local
      sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/spec_failures/ tmp/spec_failures canvas_ --allow-error --clean-dir'
      sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results.xml tmp/rspec_results canvas_ --allow-error --clean-dir'
      def reports = load 'build/new-jenkins/groovy/reports.groovy'
      reports.stashSpecFailures(prefix, index)
      reports.stashSpecResults(prefix, index)
      if (env.COVERAGE == '1') {
        sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/coverage/ tmp/spec_coverage canvas_ --clean-dir'
        reports.stashSpecCoverage(prefix, index)
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
  def successes = load 'build/new-jenkins/groovy/successes.groovy'
  if (successes.hasSuccess(prefix, total)) {
    def reports = load 'build/new-jenkins/groovy/reports.groovy'
    reports.publishSpecCoverageToS3(prefix, total, coverage_name)
  }
}

def uploadSeleniumFailures() {
  _uploadSpecFailures('selenium', seleniumConfig().node_total, 'Selenium Test Failures')
}

def uploadRSpecFailures() {
  _uploadSpecFailures('rspec', rspecConfig().node_total, 'Rspec Test Failures')
}

def _uploadSpecFailures(prefix, total, test_name) {
  def reports = load('build/new-jenkins/groovy/reports.groovy')
  def report_url = reports.publishSpecFailuresAsHTML(prefix, total, test_name)
  if (!load('build/new-jenkins/groovy/successes.groovy').hasSuccessOrBuildIsSuccessful(prefix, total)) {
    reports.appendFailMessageReport("Spec Failure For $prefix", report_url)
  }
}

def uploadSeleniumJunit() {
  def reports = load('build/new-jenkins/groovy/reports.groovy')
  reports.publishJunitReport('selenium', seleniumConfig().node_total)
}

def uploadRspecJunit() {
  def reports = load('build/new-jenkins/groovy/reports.groovy')
  reports.publishJunitReport('rspec', rspecConfig().node_total)
}

def uploadJunitReports() {
  uploadSeleniumJunit()
  uploadRspecJunit()
  def preStatus = currentBuild.getResult()
  junit allowEmptyResults: true, testResults: 'spec_results/**/*.xml'
  // junit publishing will set build status to unstable if failed tests found, if so set it back to SUCCESS
  if (currentBuild.getResult() == 'UNSTABLE' && preStatus != 'UNSTABLE') {
    currentBuild.rawBuild.@result = hudson.model.Result.SUCCESS
  }
}

return this
