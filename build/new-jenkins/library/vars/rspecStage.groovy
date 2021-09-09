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
  def rspecqNodeTotal = env.TEST_QUEUE_NODES.toInteger()
  def rspecqEnabled = useRspecQ(10)
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

  def rspecqEnvVars = baseEnvVars + [
    'COMPOSE_FILE=docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml',
    'EXCLUDE_TESTS=.*/(selenium/performance|instfs/selenium|contracts)',
    "FORCE_FAILURE=${configuration.isForceFailureSelenium() ? '1' : ''}",
    "RERUNS_RETRY=${configuration.getInteger('rspec-rerun-retry')}",
    'RSPEC_PROCESSES=6',
    "RSPECQ_FILE_SPLIT_THRESHOLD=${env.GERRIT_EVENT_TYPE == 'change-merged' ? '999' : '150'}",
    'RSPECQ_MAX_REQUEUES=2',
    'TEST_PATTERN=^./(spec|gems/plugins/.*/spec_canvas)/',
    "RSPECQ_UPDATE_TIMINGS=${env.GERRIT_EVENT_TYPE == 'change-merged' ? '1' : '0'}",
  ]

  def rspecNodeRequirements = [label: 'canvas-docker']

  if (rspecqEnabled) {
    rspecqNodeTotal.times { index ->
      extendedStage("RSpecQ Test Set ${(index + 1).toString().padLeft(2, '0')}")
        .envVars(rspecqEnvVars + ["CI_NODE_INDEX=$index"])
        .hooks([onNodeAcquired: setupNodeHook, onNodeReleasing: { tearDownNode('spec') }])
        .nodeRequirements(rspecNodeRequirements)
        .timeout(15)
        .queue(nestedStages, this.&runRspecqSuite)
    }

    extendedStage('RSpecQ Reporter for Rspec')
      .envVars(rspecqEnvVars)
      .hooks([onNodeAcquired: setupNodeHook])
      .nodeRequirements(rspecNodeRequirements)
      .timeout(15)
      .queue(nestedStages, this.&runReporter)
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
  distribution.unstashBuildScripts()
  libraryScript.execute 'bash/print-env-excluding-secrets.sh'
  def redisPassword = URLEncoder.encode("${RSPECQ_REDIS_PASSWORD}", 'UTF-8')
  env.RSPECQ_REDIS_URL = "redis://:${redisPassword}@${env.TEST_QUEUE_HOST}:6379"

  credentials.withStarlordCredentials { ->
    sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
  }

  sh(script: 'build/new-jenkins/docker-compose-build-up.sh', label: 'Start Containers')
}

def tearDownNode(prefix) {
  sh 'rm -rf ./tmp && mkdir -p tmp'
  sh 'build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results tmp/rspec_results canvas_ --allow-error --clean-dir'
  sh "build/new-jenkins/docker-copy-files.sh /usr/src/app/log/spec_failures/ tmp/spec_failures/$prefix canvas_ --allow-error --clean-dir"

  if (configuration.getBoolean('upload-docker-logs', 'false')) {
    sh "docker ps -aq | xargs -I{} -n1 -P1 docker logs --timestamps --details {} 2>&1 > tmp/docker-${prefix}-${env.CI_NODE_INDEX}.log"
    archiveArtifacts(artifacts: "tmp/docker-${prefix}-${env.CI_NODE_INDEX}.log")
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
    def workers = [:]
    def rspecProcesses = env.RSPEC_PROCESSES.toInteger()

    rspecProcesses.times { index ->
      def workerName = "${env.JOB_NAME}_worker${CI_NODE_INDEX}-${index}"
      workers[workerName] = { ->
        def workerStartTime = System.currentTimeMillis()
        sh(script: "docker-compose exec -e ENABLE_AXE_SELENIUM \
                                        -e RSPECQ_ENABLED \
                                        -e SENTRY_DSN \
                                        -e RAILS_DB_NAME_TEST=canvas_test_${index} \
                                        -e RSPECQ_UPDATE_TIMINGS \
                                        -T canvas bundle exec rspecq \
                                          --build ${env.JOB_NAME}_build${BUILD_NUMBER} \
                                          --worker ${workerName} \
                                          --include-pattern '${TEST_PATTERN}'  \
                                          --exclude-pattern '${EXCLUDE_TESTS}' \
                                          --junit-output log/results/junit{{JOB_INDEX}}-${index}.xml \
                                          --queue-wait-timeout 120 \
                                          -- --require './spec/formatters/error_context/stderr_formatter.rb' \
                                          --require './spec/formatters/error_context/html_page_formatter.rb' \
                                          --format ErrorContext::HTMLPageFormatter \
                                          --format ErrorContext::StderrFormatter .")
        def workerEndTime = System.currentTimeMillis()

        //To Do: remove once data gathering exercise is complete and RspecQ is enabled by default.
        def specCount = sh(script: "docker-compose exec -e ${env.RSPECQ_REDIS_PASSWORD} -T redis redis-cli -h ${env.TEST_QUEUE_HOST} -p 6379 llen ${env.JOB_NAME}_build${BUILD_NUMBER}:queue:jobs_per_worker:${workerName}", returnStdout: true).trim()

        reportToSplunk('test_queue_worker_ended', [
            'workerName': workerName,
            'workerRunTime': workerEndTime - workerStartTime,
            'wokerSpecCount' : specCount,
        ])
      }
    }
    parallel(workers)
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
                                            --build=${env.JOB_NAME}_build${BUILD_NUMBER} \
                                            --queue-wait-timeout 120 \
                                            --redis-url ${env.RSPECQ_REDIS_URL} \
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

def useRspecQ(percentage) {
  if (configuration.isRspecqEnabled()) {
    return true
  }

  java.security.SecureRandom random = new java.security.SecureRandom()
  if (!(env.RSPECQ_ENABLED == '1' && random.nextInt((100 / percentage).intValue()) == 0)) {
    env.RSPECQ_ENABLED = '0'
    return false
  }

  return true
}
