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

def config() {
  [
    selenium_node_total: (env.SELENIUM_CI_NODE_TOTAL ?: '25') as Integer,
    selenium_max_fail: (env.SELENIUM_MAX_FAIL ?: "100") as Integer,
    selenium_reruns_retry: (env.SELENIUM_RERUN_RETRY ?: "3") as Integer,
    rspec_node_total: (env.RSPEC_CI_NODE_TOTAL ?: '15') as Integer,
    rspec_max_fail: (env.RSPEC_MAX_FAIL ?: "100") as Integer,
    rspec_reruns_retry: (env.RSPEC_RERUN_RETRY ?: "1") as Integer
  ]
}

def runSeleniumSuite(total, index) {
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
      'selenium',
      config().selenium_max_fail,
      config().selenium_reruns_retry,
      '{spec/selenium,gems/plugins/*/spec_canvas/selenium}/**/*_spec.rb',
      '/performance/'
  )
}

def runRSpecSuite(total, index) {
  _runRspecTestSuite(
      total,
      index,
      'docker-compose.new-jenkins.yml',
      'rspec',
      config().rspec_max_fail,
      config().rspec_reruns_retry,
      '{spec,gems/plugins/*/spec_canvas}/**/*_spec.rb',
      '/selenium/'
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
    exclude_regex) {
  withEnv([
      "TEST_ENV_NUMBER=$index",
      "CI_NODE_INDEX=$index",
      "CI_NODE_TOTAL=$total",
      "COMPOSE_FILE=$compose",
      "RERUNS_RETRY=$reruns_retry",
      "MAX_FAIL=$max_fail",
      "KNAPSACK_ENABLED=1",
      "KNAPSACK_GENERATE_REPORT='false'",
      "KNAPSACK_TEST_DIR=spec",
      "KNAPSACK_TEST_FILE_PATTERN=$test_file_pattern",
      "KNAPSACK_EXCLUDE_REGEX=$exclude_regex"
  ]) {
    try {
      sh 'rm -rf ./tmp'
      sh 'build/new-jenkins/docker-cleanup.sh'
      sh 'mkdir -p tmp'
      timeout(time: 60) {
        sh 'build/new-jenkins/print-env-excluding-secrets.sh'
        sh 'build/new-jenkins/docker-compose-pull.sh'
        sh 'build/new-jenkins/docker-compose-pull-selenium.sh'
        sh 'build/new-jenkins/docker-compose-build-up.sh'
        sh 'build/new-jenkins/docker-compose-create-migrate-database.sh'
        sh 'build/new-jenkins/rspec-with-retries.sh'
      }
    }
    finally {
      // copy spec failures to local
      sh 'mkdir -p tmp'
      sh(
          script: 'docker cp $(docker-compose ps -q web):/usr/src/app/log/spec_failures/ ./tmp/spec_failures/',
          returnStatus: true
      )

      def reports = load 'build/new-jenkins/groovy/reports.groovy'
      reports.stashSpecFailures(prefix, index)
      if (env.COVERAGE == '1') {
        sh 'docker cp $(docker-compose ps -q web):/usr/src/app/coverage/ ./tmp/spec_coverage/'
        reports.stashSpecCoverage(prefix, index)
      }
      sh 'rm -rf ./tmp'
      sh 'build/new-jenkins/docker-cleanup.sh --allow-failure'
    }
  }
}

def uploadSeleniumCoverage() {
  _uploadCoverage('selenium', config().selenium_node_total, 'canvas-lms-selenium')
}

def uploadRSpecCoverage() {
  _uploadCoverage('rspec', config().rspec_node_total, 'canvas-lms-rspec')
}

def _uploadCoverage(prefix, total, coverage_name) {
  def reports = load 'build/new-jenkins/groovy/reports.groovy'
  reports.publishSpecCoverageToS3(prefix, total, coverage_name)
}

def uploadSeleniumFailures() {
  _uploadSpecFailures('selenium', config().selenium_node_total, 'Selenium Test Failures')
}

def uploadRSpecFailures() {
  _uploadSpecFailures('rspec', config().rspec_node_total, 'Rspec Test Failures')
}

def _uploadSpecFailures(prefix, total, test_name) {
  def reports = load 'build/new-jenkins/groovy/reports.groovy'
  reports.publishSpecFailuresAsHTML(prefix, total, test_name)
}

return this