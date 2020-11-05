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

def stashSpecCoverage(prefix, index) {
  dir("tmp") {
    stash name: "${prefix}_spec_coverage_${index}", includes: 'spec_coverage/**/*'
  }
}

def cleanupCoverage(prefix) {
  sh 'rm -vrf ./coverage_nodes'
  sh 'rm -vrf ./coverage'
  sh "rm -vrf coverage_nodes ${prefix}_coverage_nodes"
  sh "rm -vrf coverage ${prefix}_coverage"
}

def publishSpecCoverageToS3(prefix, ci_node_total, coverage_type) {
  echo "publishing coverage for $coverage_type: $ci_node_total for $prefix"

  cleanupCoverage(prefix)

  // get all the data for the report
  dir('coverage_nodes') {
    for(int index = 0; index < ci_node_total; index++) {
      dir("node_${index}") {
        unstash "${prefix}_spec_coverage_${index}"
      }
    }
  }

  // build the report
  sh './build/new-jenkins/rspec-coverage-report.sh'

  // upload to s3
  uploadCoverage([
      uploadSource: "/coverage",
      uploadDest: "$coverage_type/coverage"
  ])

  // archive for debugging
  sh "mv coverage_nodes ${prefix}_coverage_nodes"
  sh "mv coverage ${prefix}_coverage"
  archiveArtifacts(artifacts: "${prefix}_coverage_nodes/**")
  archiveArtifacts(artifacts: "${prefix}_coverage/**")

  cleanupCoverage(prefix)
}

def stashParallelLogs(prefix, index) {
  dir("tmp") {
    stash name: "${prefix}_spec_parallel_${index}", includes: 'parallel_runtime_rspec_tests/**/*.log'
  }
}

def copyParallelLogs(rspecTotal, seleniumTotal) {
  dir('parallel_logs') {
    for(int index = 0; index < rspecTotal; index++) {
      dir("rspec_node_${index}") {
        try {
          unstash "rspec_spec_parallel_${index}"
        } catch(err) {
          println (err)
        }
      }
    }
    for(int index = 0; index < seleniumTotal; index++) {
      dir("selenium_node_${index}") {
        try {
          unstash "selenium_spec_parallel_${index}"
        } catch(err) {
          println (err)
        }
      }
    }
    sh '../build/new-jenkins/parallel-log-combine.sh'
  }
}

return this
