#!/usr/bin/env groovy

/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

library "canvas-builds-library@${env.CANVAS_BUILDS_REFSPEC}"
loadLocalLibrary('local-lib', 'build/new-jenkins/library')

env.BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
env.COMPOSE_FILE = 'docker-compose.new-jenkins-js.yml'
env.DOCKER_BUILDKIT = 1
env.FORCE_FAILURE = commitMessageFlag('force-failure-js').asBooleanInteger()
env.SELENIUM_NODE_IMAGE = '948781806214.dkr.ecr.us-east-1.amazonaws.com/docker.io/selenium/node-chromium:126.0-20240621'
env.SELENIUM_HUB_IMAGE = '948781806214.dkr.ecr.us-east-1.amazonaws.com/docker.io/selenium/hub:4.22.0'

node(nodeLabel()) {
  timeout(time: 20, unit: 'MINUTES') {
    ansiColor('xterm') {
      timestamps {
        def tests = [:]
        try {
          for (int i = 0; i < jsTestsStage.VITEST_NODE_COUNT; i++) {
            def index = i
            def stageName = "Vitest ${index}"
            tests[stageName] = {
              jsTestsStage.runVitestNode(index)
            }
          }

          // Packages runs on the main coordinator node
          tests['Packages'] = {
            def stageName = 'Packages'
            def stageStartTime = System.currentTimeMillis()
            try {
              stage("${stageName} - Cleanup") {
                pipelineHelpers.cleanupWorkspace()
              }

              stage("${stageName} - Setup") {
                jsTestsStage.checkoutCode()
                jsTestsStage.provisionDocker()
                jsTestsStage.startServices()
              }

              def envVars = [
                "FORCE_FAILURE=${env.FORCE_FAILURE}",
                "RAILS_ENV=test",
                "TEST_RESULT_OUTPUT_DIR=js-results/packages"
              ]
              def envFlags = envVars.collect { "-e ${it}" }.join(' ')

              stage("${stageName} - Run Tests") {
                try {
                  sh("docker compose -f ${env.COMPOSE_FILE} exec -T ${envFlags} canvas bash -c 'TEST_RESULT_OUTPUT_DIR=/usr/src/app/\$TEST_RESULT_OUTPUT_DIR yarn test:packages'")
                } finally {
                  pipelineHelpers.copyFromContainer('canvas', '/usr/src/app/js-results/packages', './js-results/packages')
                  archiveArtifacts artifacts: "js-results/packages/**/*.xml"
                  junit "js-results/packages/**/*.xml"

                  if (env.COVERAGE == '1') {
                    jsTestsStage.collectCoverage('Packages')
                  }
                }
              }
            } finally {
              pipelineHelpers.cleanupDocker()
            }
          }

          parallel(tests)
        } finally {
          // Collect all build summary data on coordinator node after parallel stages complete
          stage('Collect Build Summary Data') {
            // Analyze the entire JS build from the coordinator node
            tests.each { stageName, closure ->
              buildSummaryReport.addFailureRun(stageName, currentBuild)
              buildSummaryReport.addRunTestActions(stageName, currentBuild)
            }
          }

          buildSummaryReport.saveRunManifest()
        }
      }
    }
  }
}
