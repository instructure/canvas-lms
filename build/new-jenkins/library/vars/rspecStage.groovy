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
  def rspecqNodeTotal = configuration.getInteger('rspecq-ci-node-total')
  def rspecqEnabled = env.RSPECQ_ENABLED == '1' || configuration.isRspecqEnabled()
  def setupNodeHook = this.&setupNode

  def baseEnvVars = [
    "ENABLE_AXE_SELENIUM=${env.ENABLE_AXE_SELENIUM}",
    'POSTGRES_PASSWORD=sekret',
    'SELENIUM_VERSION=3.141.59-20201119',
    "RSPECQ_ENABLED=${env.RSPECQ_ENABLED}"
  ]

  def rspecEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$rspecNodeTotal",
    'COMPOSE_FILE=docker-compose.new-jenkins.yml',
    'EXCLUDE_TESTS=.*/(selenium|contracts)',
    "FORCE_FAILURE=${configuration.isForceFailureRSpec() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('rspec-rerun-retry')}",
    "RSPEC_PROCESSES=${configuration.getInteger('rspec-processes')}",
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/',
  ]

  def seleniumEnvVars = baseEnvVars + [
    "CI_NODE_TOTAL=$seleniumNodeTotal",
    'COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
    'EXCLUDE_TESTS=.*/performance',
    "FORCE_FAILURE=${configuration.isForceFailureSelenium() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('selenium-rerun-retry')}",
    "RSPEC_PROCESSES=${configuration.getInteger('selenium-processes')}",
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/selenium',
  ]

  def rspecqEnvVars = baseEnvVars + [
    'COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
    'EXCLUDE_TESTS=.*/(selenium/performance|instfs/selenium|contracts)',
    "FORCE_FAILURE=${configuration.isForceFailureSelenium() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('rspecq-max-requeues')}",
    "RSPEC_PROCESSES=${configuration.getInteger('rspecq-processes')}",
    "RSPECQ_FILE_SPLIT_THRESHOLD=${configuration.fileSplitThreshold()}",
    "RSPECQ_MAX_REQUEUES=${configuration.getInteger('rspecq-max-requeues')}",
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/',
    "RSPECQ_UPDATE_TIMINGS=${env.GERRIT_EVENT_TYPE == 'change-merged' ? '1' : '0'}",
  ]

  def rspecNodeRequirements = [label: 'canvas-docker']

  if (rspecqEnabled) {
    extendedStage('RSpecQ Reporter for Rspec')
        .envVars(rspecqEnvVars)
        .hooks([onNodeAcquired: setupNodeHook])
        .nodeRequirements(rspecNodeRequirements)
        .timeout(15)
        .queue(nestedStages, this.&runReporter)

    rspecqNodeTotal.times { index ->
      extendedStage("RSpecQ Test Set ${(index + 1).toString().padLeft(2, '0')}")
          .envVars(rspecqEnvVars + ["CI_NODE_INDEX=$index"])
          .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('spec') }])
          .nodeRequirements(rspecNodeRequirements)
          .timeout(15)
          .queue(nestedStages, this.&runRspecqSuite)
    }
  } else {
    rspecNodeTotal.times { index ->
      extendedStage("RSpec Test Set ${(index + 1).toString().padLeft(2, '0')}")
        .envVars(rspecEnvVars + ["CI_NODE_INDEX=$index"])
        .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('rspec') }])
        .nodeRequirements(rspecNodeRequirements)
        .timeout(15)
        .queue(nestedStages, this.&runLegacySuite)
    }

    seleniumNodeTotal.times { index ->
      extendedStage("Selenium Test Set ${(index + 1).toString().padLeft(2, '0')}")
        .envVars(seleniumEnvVars + ["CI_NODE_INDEX=$index"])
        .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('selenium') }])
        .nodeRequirements(rspecNodeRequirements)
        .timeout(15)
        .queue(nestedStages, this.&runLegacySuite)
    }
  }
}

def setupNode() {
  env.AUTO_CANCELLED = 'false'
  distribution.unstashBuildScripts()
  if (queue_empty()) {
    catchError([buildResult: 'SUCCESS', stageResult: 'ABORTED']) {
      env.AUTO_CANCELLED = 'true'
      error 'Test queue is empty, releasing node.'
    }
    return
  }
  libraryScript.execute 'bash/print-env-excluding-secrets.sh'
  if (env.RSPECQ_ENABLED == '1') {
    def redisPassword = URLEncoder.encode("${env.RSPECQ_REDIS_PASSWORD ?: ''}", 'UTF-8')
    env.RSPECQ_REDIS_URL = "redis://:${redisPassword}@${TEST_QUEUE_HOST}:6379"
  }
  credentials.withStarlordCredentials { ->
    sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
  }

  sh(script: 'build/new-jenkins/docker-compose-build-up.sh', label: 'Start Containers')
}

def tearDownNode(prefix) {
  if (env.AUTO_CANCELLED.toBoolean()) {
    println 'Test queue is empty, releasing node.'
    return
  }
  sh 'rm -rf ./tmp && mkdir -p tmp'
  sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results tmp/rspec_results canvas_ --allow-error --clean-dir'
  sh "build/new-jenkins/docker-copy-files.sh /usr/src/app/log/spec_failures/ tmp/spec_failures/$prefix canvas_ --allow-error --clean-dir"

  if (configuration.getBoolean('upload-docker-logs', 'false')) {
    sh "docker ps -aq | xargs -I{} -n1 -P1 docker logs --timestamps --details {} 2>&1 > tmp/docker-${prefix}-${CI_NODE_INDEX}.log"
    archiveArtifacts(artifacts: "tmp/docker-${prefix}-${CI_NODE_INDEX}.log")
  }

  if (env.ENABLE_AXE_SELENIUM == '1') {
    archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/rspec_results/**/*'
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

def runRspecqSuite() {
  try {
    if (env.AUTO_CANCELLED.toBoolean()) {
      println 'Test queue is empty, releasing node.'
      return
    }
    sh(script: 'docker-compose exec -T -e ENABLE_AXE_SELENIUM \
                                       -e RSPECQ_ENABLED \
                                       -e SENTRY_DSN \
                                       -e RSPECQ_UPDATE_TIMINGS \
                                       -e JOB_NAME \
                                       -e BUILD_NUMBER canvas bash -c \'build/new-jenkins/rspecq-tests.sh\'', label: 'Run RspecQ Tests')
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

def runLegacySuite() {
  try {
    sh(script: 'docker-compose exec -T -e RSPEC_PROCESSES -e ENABLE_AXE_SELENIUM canvas bash -c \'build/new-jenkins/rspec-with-retries.sh\'', label: 'Run Tests')
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
  def queueInfo = sh(script: "docker run -e REDISCLI_AUTH=${env.RSPECQ_REDIS_PASSWORD} -e TEST_QUEUE_HOST -t --rm $REGISTRY_BASE/redis:alpine /bin/sh -c '\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 llen ${JOB_NAME}_build${BUILD_NUMBER}:queue:unprocessed;\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 scard ${JOB_NAME}_build${BUILD_NUMBER}:queue:processed;\
                                      redis-cli -h $TEST_QUEUE_HOST -p 6379 get ${JOB_NAME}_build${BUILD_NUMBER}:queue:status'", returnStdout: true).split('\n')
  def queueUnprocessed = queueInfo[0].split(' ')[1].trim()
  def queueProcessed = queueInfo[1].split(' ')[1].trim()
  def queueStatus = queueInfo[2].trim()
  return queueStatus == '\"ready\"' && queueUnprocessed.toInteger() == 0 && queueProcessed.toInteger() > 1
}
