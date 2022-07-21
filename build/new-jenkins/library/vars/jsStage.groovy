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

@Field static final COFFEE_NODE_COUNT = 4
@Field static final JSG_NODE_COUNT = 3
@Field static final JEST_NODE_COUNT = 3

def jestNodeRequirementsTemplate(index) {
  def baseTestContainer = [
    image: env.KARMA_RUNNER_IMAGE,
    command: 'cat'
  ]

  return [
    containers: [baseTestContainer + [name: "jest${index}"]]
  ]
}

def coffeeNodeRequirementsTemplate() {
  def baseTestContainer = [
    image: env.KARMA_RUNNER_IMAGE,
    command: 'cat'
  ]

  return [
    containers: (0..COFFEE_NODE_COUNT).collect { index -> baseTestContainer + [name: "coffee${index}"] }
  ]
}

def karmaNodeRequirementsTemplate() {
  def baseTestContainer = [
    image: env.KARMA_RUNNER_IMAGE,
    command: 'cat'
  ]

  def karmaContainers = []

  karmaContainers = karmaContainers + (0..JSG_NODE_COUNT).collect { index -> baseTestContainer + [name: "jsg${index}"] }
  karmaContainers = karmaContainers + ['jsa', 'jsh'].collect { group -> baseTestContainer + [name: group] }

  return [
    containers: karmaContainers,
  ]
}

def packagesNodeRequirementsTemplate() {
  def baseTestContainer = [
    image: env.KARMA_RUNNER_IMAGE,
    command: 'cat'
  ]

  return [
    containers: [baseTestContainer + [name: "packages"]],
  ]
}

def tearDownNode() {
  return {
    copyToWorkspace srcBaseDir: '/usr/src/app', path: env.TEST_RESULT_OUTPUT_DIR
    archiveArtifacts artifacts: "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"
    junit "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"

    if (env.COVERAGE == '1') {
      /* groovylint-disable-next-line GStringExpressionWithinString */
      sh '''#!/bin/bash
        rm -vrf ./coverage-report-js
        mkdir -v coverage-report-js
        chmod -vvR 777 coverage-report-js

        counter=0
        for coverage_file in `find . -type d -name node_modules -prune -o -name coverage*.json -print`
        do
          stagearray=($STAGE_NAME)
          new_file="./coverage-report-js/coverage-"${stagearray[0]}"-"$counter".json"
          cp $coverage_file $new_file
          ((counter=counter+1))
        done
      '''
      copyToWorkspace srcBaseDir: '/usr/src/app', path: 'coverage-report-js'
      archiveArtifacts allowEmptyArchive: true, artifacts: 'coverage-report-js/*'
    }
  }
}

def queueCoffeeDistribution() {
  { stages ->
    COFFEE_NODE_COUNT.times { index ->
      def coffeeEnvVars = [
        "CI_NODE_INDEX=${index}",
        "CI_NODE_TOTAL=${COFFEE_NODE_COUNT}",
        'JSPEC_GROUP=coffee',
      ]

      callableWithDelegate(queueTestStage())(stages, "coffee${index}", coffeeEnvVars, 'yarn test:karma:headless')
    }
  }
}

def queueJestDistribution(index) {
  { stages ->
    def jestEnvVars = [
      "CI_NODE_INDEX=${index.toInteger() + 1}",
      "CI_NODE_TOTAL=${JEST_NODE_COUNT}",
    ]

    callableWithDelegate(queueTestStage())(stages, "jest${index}", jestEnvVars, 'yarn test:jest:build')
  }
}

def queueKarmaDistribution() {
  { stages ->
    JSG_NODE_COUNT.times { index ->
      def jsgEnvVars = [
        "CI_NODE_INDEX=${index}",
        "CI_NODE_TOTAL=${JSG_NODE_COUNT}",
        'JSPEC_GROUP=jsg',
      ]

      callableWithDelegate(queueTestStage())(stages, "jsg${index}", jsgEnvVars, 'yarn test:karma:headless')
    }

    ['jsa', 'jsh'].each { group ->
      callableWithDelegate(queueTestStage())(stages, "${group}", ["JSPEC_GROUP=${group}"], 'yarn test:karma:headless')
    }
  }
}

def queuePackagesDistribution() {
  { stages ->
    callableWithDelegate(queueTestStage())(stages, 'packages', ["CANVAS_RCE_PARALLEL=1"], 'TEST_RESULT_OUTPUT_DIR=/usr/src/app/$TEST_RESULT_OUTPUT_DIR yarn test:packages:parallel')
  }
}

def queueTestStage() {
  { stages, containerName, additionalEnvVars, scriptName ->
    def baseEnvVars = [
      "FORCE_FAILURE=${env.FORCE_FAILURE}",
      'RAILS_ENV=test',
      "TEST_RESULT_OUTPUT_DIR=js-results/${containerName}",
    ]

    def postStageHandler = [
      onStageEnded: { stageName, stageConfig, result ->
        buildSummaryReport.setStageTimings(stageName, stageConfig.timingValues())
      }
    ]

    extendedStage(containerName)
      .envVars(baseEnvVars + additionalEnvVars)
      .hooks(postStageHandler + [onNodeReleasing: this.tearDownNode()])
      .obeysAllowStages(false)
      .nodeRequirements(container: containerName)
      .queue(stages) { sh(scriptName) }
  }
}
