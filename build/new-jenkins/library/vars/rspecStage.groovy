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

import groovy.transform.Field
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def setupNode() {
  try {
    distribution.unstashBuildScripts()
    libraryScript.execute 'bash/print-env-excluding-secrets.sh'
    credentials.withStarlordCredentials { ->
      sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
    }

    sh(script: 'build/new-jenkins/docker-compose-build-up.sh', label: 'Start Containers')
  } catch (err) {
    if (!(err instanceof FlowInterruptedException)) {
      send_slack_alert(err)
      echo "RspecQ node ${env.CI_NODE_INDEX} setup failed: ${err}"
      currentBuild.result = 'UNSTABLE'
      // Fail loudly to prevent confusing downstream failures
      error "RspecQ node ${env.CI_NODE_INDEX} setup failed - aborting to prevent confusing failures in Run Tests stage"
    }
    throw err
  }
}

def tearDownNode() {
  def destDir = "tmp/${env.CI_NODE_INDEX}"
  def srcDir = "${env.COMPOSE_PROJECT_NAME}-canvas-1:/usr/src/app"
  def uploadDockerLogs = commitMessageFlag('upload-docker-logs') as Boolean

  sh """#!/bin/bash
    set -ex

    rm -rf ./tmp && mkdir -p $destDir ${destDir}_rspec_results
    docker cp ${srcDir}/log/results ${destDir}_rspec_results/ || true
    docker cp ${srcDir}/log/spec_failures ${destDir}/spec_failures/ || true
    docker cp ${srcDir}/log/skipped ${destDir}/skipped/ || true

    tar cvfz ${destDir}/rspec_results.tgz ${destDir}_rspec_results/

    if [[ "\$COVERAGE" == "1" ]]; then
      docker cp ${srcDir}/coverage ${destDir}/coverage/ || true
    fi

    if [[ "\$CRYSTALBALL_MAP" == "1" ]]; then
      docker cp ${srcDir}/log/results/crystalball_results ${destDir}/crystalball/ || true
    fi

    if [[ "\$RSPEC_LOG" == "1" ]]; then
      docker cp ${srcDir}/log/parallel_runtime ${destDir}/parallel_runtime_rspec_tests/ || true
    fi

    if [[ "${uploadDockerLogs}" = "1" ]]; then
      docker ps -aq | xargs -I{} -n1 -P1 docker logs --timestamps --details {} 2>&1 > ${destDir}/docker.log
    fi

    find tmp
  """

  archiveArtifacts allowEmptyArchive: true, artifacts: "$destDir/**/*"

  findFiles(glob: "$destDir/spec_failures/**/index.html").each { file ->
    // tmp/node_18/spec_failures/Initial/spec/selenium/force_failure_spec.rb:20/TestFailure::ErrorClass/index
    // split on the 5th to give us the rerun category (Initial, Rerun_1, Rerun_2...)
    def splitPath = file.getPath().split('/')
    def pathCategory = splitPath[3]
    def specTitle = splitPath.toList().subList(4, splitPath.size() - 2).join('/')
    def errorClass = splitPath[splitPath.size() - 2]

    def finalCategory = env.RERUNS_RETRY.toInteger() == 0 ? 'Initial' : "Rerun_${env.RERUNS_RETRY.toInteger()}"
    def artifactsPath = "${currentBuild.getAbsoluteUrl()}artifact/${file.getPath()}"

    buildSummaryReport.addFailurePath(specTitle, artifactsPath, pathCategory)
    buildSummaryReport.setFailureDetails(specTitle, errorClass)

    if (pathCategory == finalCategory) {
      buildSummaryReport.setFailureCategory(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_NEVER_PASSED)
    } else {
      buildSummaryReport.setFailureCategoryUnlessExists(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_PASSED_ON_RETRY)
    }
  }

  // Find and process skipped tests
  findFiles(glob: "$destDir/skipped/**/*.json").each { skipFile ->
    // Skip empty files to avoid JSON parse errors
    if (skipFile.length == 0) {
      echo "Skipping empty file: ${skipFile.path}"
      return
    }

    try {
      def skipReport = readJSON file: skipFile.path

      skipReport.pending?.each { test ->
        buildSummaryReport.addSkippedTest(test.location, test)
      }

      // Explicitly extract fields to avoid Jenkins readJSON LazyMap serialization issues
      def eventData = [
        summary: [
          total_examples: skipReport.summary?.total_examples,
          total_pending: skipReport.summary?.total_pending,
          generated_at: skipReport.summary?.generated_at
        ],
        pending: skipReport.pending?.collect { test ->
          [
            description: test.description,
            location: test.location,
            file_path: test.file_path,
            line_number: test.line_number,
            execution_result: test.execution_result,
            reason: test.reason,
            pending_fixed: test.pending_fixed,
            jira_number: test.jira_number,
            skip_date: test.skip_date,
            timestamp: test.timestamp
          ]
        } ?: []
      ]

      reportBuildLog("rspecq_test_data", eventData, "observe-test-tracking-token")
    } catch (Exception e) {
      echo "Failed to process skip report file ${skipFile.path}: ${e.message}"
      // Continue processing other files
    }
  }
}

def runRspecqSuite() {
  try {
    sh(script: 'docker compose exec -T -e ENABLE_AXE_SELENIUM \
                                       -e SENTRY_DSN \
                                       -e RSPECQ_UPDATE_TIMINGS \
                                       -e RSPECQ_WORKER_LIVENESS_SEC \
                                       -e JOB_NAME \
                                       -e COVERAGE \
                                       -e BUILD_NAME \
                                       -e BUILD_NUMBER \
                                       -e CRYSTALBALL_MAP \
                                       -e CI_NODE_INDEX \
                                       -e CRYSTAL_BALL_SPECS canvas bash -c \'build/new-jenkins/rspecq-tests.sh\'', label: 'Run RspecQ Tests')
  } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
    if (e.causes[0] instanceof org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution.ExceededTimeout) {
      /* groovylint-disable-next-line GStringExpressionWithinString */
      sh '''#!/bin/bash
        ids=( $(docker ps -aq --filter "name=canvas-") )
        for i in "${ids[@]}"
        do
          docker exec $i bash -c "cat /usr/src/app/log/cmd_output/*.log"
        done
      '''
    }

    throw e
  } catch (err) {
    if (err instanceof FlowInterruptedException) {
      throw err
    }
    send_slack_alert(err)
    echo "RspecQ node ${env.CI_NODE_INDEX} failed: ${err}"
    currentBuild.result = 'UNSTABLE'
    throw err
  }
}

def send_slack_alert(error) {
  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'danger',
    message: """<${env.BUILD_URL}|RspecQ node failure: ${error}>"""
  )
}

def runRspecQWorkerNode(index, additionalEnvVars = []) {
  def stageName = "RSpecQ Set ${index}"
  node(nodeLabel()) {
    def stageStartTime = System.currentTimeMillis()
    try {
      stage("${index} Cleanup") {
        pipelineHelpers.cleanupWorkspace()
      }

      stage("${index} Setup") {
        setupNode()
      }

      def baseEnvVars = [
        "CI_NODE_INDEX=${index}",
        "BUILD_NAME=${env.JOB_NAME}_build${env.BUILD_NUMBER}"
      ]
      def envVars = baseEnvVars + additionalEnvVars

      withEnv(envVars) {
        stage("${index} Run Tests") {
          try {
            runRspecqSuite()
          } finally {
            buildSummaryReport.trackStage(stageName, stageStartTime)
          }
        }

        stage("${index} Collect Results") {
          tearDownNode()
        }
      }
    } finally {
      pipelineHelpers.cleanupDocker()
    }
  }
}

return this
