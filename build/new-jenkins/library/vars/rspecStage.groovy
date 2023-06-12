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

@Field static final SUCCESS_NOT_BUILT = [buildResult: 'SUCCESS', stageResult: 'NOT_BUILT']
@Field static final SUCCESS_UNSTABLE = [buildResult: 'SUCCESS', stageResult: 'UNSTABLE']

def createDistribution(nestedStages) {
  def rspecqNodeTotal = commitMessageFlag('rspecq-ci-node-total') as Integer
  def setupNodeHook = this.&setupNode

  def baseEnvVars = [
    "ENABLE_AXE_SELENIUM=${env.ENABLE_AXE_SELENIUM}",
    'POSTGRES_PASSWORD=sekret'
  ]

  def rspecqEnvVars = baseEnvVars + [
    'COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
    'EXCLUDE_TESTS=.*/(selenium/performance|instfs/selenium|contracts)',
    "FORCE_FAILURE=${commitMessageFlag('force-failure-rspec').asBooleanInteger()}",
    "RERUNS_RETRY=${commitMessageFlag('rspecq-max-requeues') as Integer}",
    "RSPEC_PROCESSES=${commitMessageFlag('rspecq-processes') as Integer}",
    "RSPECQ_MAX_REQUEUES=${commitMessageFlag('rspecq-max-requeues') as Integer}",
    "RSPECQ_UPDATE_TIMINGS=${env.GERRIT_EVENT_TYPE == 'change-merged' ? '1' : '0'}",
  ]

  if(env.CRYSTALBALL_MAP == '1') {
    rspecqEnvVars = rspecqEnvVars + ['RSPECQ_FILE_SPLIT_THRESHOLD=9999', 'CRYSTALBALL_MAP=1']
  } else {
    rspecqEnvVars = rspecqEnvVars + ["RSPECQ_FILE_SPLIT_THRESHOLD=${commitMessageFlag('rspecq-file-split-threshold') as Integer}"]
  }

  if(env.ENABLE_AXE_SELENIUM == '1') {
    rspecqEnvVars = rspecqEnvVars + ['TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/selenium']
  } else {
    rspecqEnvVars = rspecqEnvVars + ['TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/']
  }

  extendedStage('RSpecQ Reporter for Rspec')
    .envVars(rspecqEnvVars)
    .hooks(buildSummaryReportHooks.call() + [onNodeAcquired: setupNodeHook])
    .nodeRequirements([label: nodeLabel()])
    .timeout(15)
    .queue(nestedStages, this.&runReporter)

  rspecqNodeTotal.times { index ->
    extendedStage("RSpecQ Test Set ${(index + 1).toString().padLeft(2, '0')}")
      .envVars(rspecqEnvVars + ["CI_NODE_INDEX=$index"])
      .hooks(buildSummaryReportHooks.call() + [onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode() }])
      .nodeRequirements([label: nodeLabel()])
      .timeout(15)
      .queue(nestedStages, this.&runRspecqSuite)
  }
}

def setupNode() {
  try {
    env.AUTO_CANCELLED = env.AUTO_CANCELLED ?: ''
    distribution.unstashBuildScripts()
    if (queue_empty()) {
      env.AUTO_CANCELLED += "${env.CI_NODE_INDEX},"
      cancel_node(SUCCESS_NOT_BUILT, 'Test queue is empty, releasing node.')
      return
    }
    libraryScript.execute 'bash/print-env-excluding-secrets.sh'
    credentials.withStarlordCredentials { ->
      sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
    }

    sh(script: 'build/new-jenkins/docker-compose-build-up.sh', label: 'Start Containers')
  } catch (err) {
    if (!(err instanceof FlowInterruptedException)) {
      send_slack_alert(err)
      env.AUTO_CANCELLED += "${env.CI_NODE_INDEX},"
      cancel_node(SUCCESS_UNSTABLE, "RspecQ node setup failed!: ${err}")
      return
    }
    throw err
  }
}

def tearDownNode() {
  if (env.AUTO_CANCELLED?.split(',')?.contains("${env.CI_NODE_INDEX}")) {
    cancel_node(SUCCESS_NOT_BUILT, 'Node cancelled!')
    return
  }

  def destDir = "tmp/${env.CI_NODE_INDEX}"
  def srcDir = "${env.COMPOSE_PROJECT_NAME}_canvas_1:/usr/src/app"
  def uploadDockerLogs = commitMessageFlag('upload-docker-logs') as Boolean

  sh """#!/bin/bash
    set -ex

    rm -rf ./tmp && mkdir -p $destDir ${destDir}_rspec_results
    docker cp ${srcDir}/log/results ${destDir}_rspec_results/ || true
    docker cp ${srcDir}/log/spec_failures ${destDir}/spec_failures/ || true

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

    def finalCategory = reruns_retry.toInteger() == 0 ? 'Initial' : "Rerun_${reruns_retry.toInteger()}"
    def artifactsPath = "${currentBuild.getAbsoluteUrl()}artifact/${file.getPath()}"

    buildSummaryReport.addFailurePath(specTitle, artifactsPath, pathCategory)
    buildSummaryReport.setFailureDetails(specTitle, errorClass)

    if (pathCategory == finalCategory) {
      buildSummaryReport.setFailureCategory(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_NEVER_PASSED)
    } else {
      buildSummaryReport.setFailureCategoryUnlessExists(specTitle, buildSummaryReport.FAILURE_TYPE_TEST_PASSED_ON_RETRY)
    }
  }
}

def runRspecqSuite() {
  try {
    if (env.AUTO_CANCELLED?.split(',')?.contains("${env.CI_NODE_INDEX}")) {
      cancel_node(SUCCESS_NOT_BUILT, 'Node cancelled!')
      return
    }
    sh(script: 'docker-compose exec -T -e ENABLE_AXE_SELENIUM \
                                       -e SENTRY_DSN \
                                       -e RSPECQ_UPDATE_TIMINGS \
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
        ids=( $(docker ps -aq --filter "name=canvas_") )
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
    env.AUTO_CANCELLED += "${env.CI_NODE_INDEX},"
    cancel_node(SUCCESS_UNSTABLE, "RspecQ node failed!: ${err}")
    /* groovylint-disable-next-line ReturnNullFromCatchBlock */
    return
  }
}

def runReporter() {
  try {
    sh(script: "docker-compose exec -e SENTRY_DSN -T canvas bundle exec rspecq \
                                            --build=${JOB_NAME}_build${BUILD_NUMBER} \
                                            --queue-wait-timeout 120 \
                                            --redis-url $RSPECQ_REDIS_URL \
                                            --report", label: 'Reporter')
  } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
    if (e.causes[0] instanceof org.jenkinsci.plugins.workflow.steps.TimeoutStepExecution.ExceededTimeout) {
      /* groovylint-disable-next-line GStringExpressionWithinString */
      sh '''#!/bin/bash
        ids=( $(docker ps -aq --filter "name=canvas_") )
        for i in "${ids[@]}"
        do
          docker exec $i bash -c "cat /usr/src/app/log/cmd_output/*.log"
        done
      '''
    }

    throw e
  }
}

def queue_empty() {
  env.REGISTRY_BASE = 'starlord.inscloudgate.net/jenkins'
  sh "./build/new-jenkins/docker-with-flakey-network-protection.sh pull $REGISTRY_BASE/redis:alpine"
  def queueInfo = sh(script: "docker run -e TEST_QUEUE_HOST -t --rm $REGISTRY_BASE/redis:alpine /bin/sh -c '\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 llen ${JOB_NAME}_build${BUILD_NUMBER}:queue:unprocessed;\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 scard ${JOB_NAME}_build${BUILD_NUMBER}:queue:processed;\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 get ${JOB_NAME}_build${BUILD_NUMBER}:queue:status'", returnStdout: true).split('\n')
  def queueUnprocessed = queueInfo[0].split(' ')[1].trim()
  def queueProcessed = queueInfo[1].split(' ')[1].trim()
  def queueStatus = queueInfo[2].trim()
  return queueStatus == '\"ready\"' && queueUnprocessed.toInteger() == 0 && queueProcessed.toInteger() > 1
}

def send_slack_alert(error) {
  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'danger',
    message: """<${env.BUILD_URL}|RspecQ node failure: ${error}>"""
  )
}

def cancel_node(buildResult, errorMessage) {
  catchError(buildResult) {
    error errorMessage
  }
}
