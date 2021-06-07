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

def setupNode() {
  { ->
    def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.JENKINSFILE_REFSPEC : env.CANVAS_LMS_REFSPEC

    checkoutRepo('canvas-lms', refspecToCheckout, 1)

    credentials.withStarlordDockerLogin { ->
      sh "./build/new-jenkins/docker-with-flakey-network-protection.sh pull $KARMA_RUNNER_IMAGE"
    }
  }
}

def tearDownNode() {
  { ->
    sh "mkdir -vp ${env.TEST_RESULT_OUTPUT_DIR}"
    sh "docker cp \$(docker ps -qa -f name=${env.CONTAINER_NAME}):/usr/src/app/${env.TEST_RESULT_OUTPUT_DIR} ${env.TEST_RESULT_OUTPUT_DIR}"

    sh "find ${env.TEST_RESULT_OUTPUT_DIR}"

    archiveArtifacts artifacts: "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"
    junit "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"
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

      callableWithDelegate(queueTestStage())(stages, "coffee${index}", coffeeEnvVars, 'build/new-jenkins/js/tests-karma.sh')
    }
  }
}

def queueJestDistribution() {
  { stages ->
    callableWithDelegate(queueTestStage())(stages, 'jest', [], 'build/new-jenkins/js/tests-jest.sh')
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

      callableWithDelegate(queueTestStage())(stages, "jsg${index}", jsgEnvVars, 'build/new-jenkins/js/tests-karma.sh')
    }

    ['jsa', 'jsh'].each { group ->
      callableWithDelegate(queueTestStage())(stages, "${group}", ["JSPEC_GROUP=${group}"], 'build/new-jenkins/js/tests-karma.sh')
    }

    callableWithDelegate(queueTestStage())(stages, 'packages', [], 'build/new-jenkins/js/tests-packages.sh')
  }
}

def queueTestStage() {
  { stages, containerName, additionalEnvVars, scriptName ->
    def baseEnvVars = [
      "CONTAINER_NAME=${containerName}",
      "TEST_RESULT_OUTPUT_DIR=js-results/${containerName}",
    ]

    extendedStage(containerName)
      .envVars(baseEnvVars + additionalEnvVars)
      .hooks([onNodeReleasing: this.tearDownNode()])
      .obeysAllowStages(false)
      .queue(stages) { sh(scriptName) }
  }
}
