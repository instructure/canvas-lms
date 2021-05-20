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

def setupNode() {
  def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.JENKINSFILE_REFSPEC : env.CANVAS_LMS_REFSPEC

  checkoutRepo('canvas-lms', refspecToCheckout, 1)

  credentials.withStarlordDockerLogin { ->
    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh pull $KARMA_RUNNER_IMAGE"
  }
}

def tearDownNode() {
  sh "mkdir -vp ${env.TEST_RESULT_OUTPUT_DIR}"
  sh "docker cp \$(docker ps -qa -f name=${env.CONTAINER_NAME}):/usr/src/app/${env.TEST_RESULT_OUTPUT_DIR} ${env.TEST_RESULT_OUTPUT_DIR}"

  sh "find ${env.TEST_RESULT_OUTPUT_DIR}"

  archiveArtifacts artifacts: "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"
  junit "${env.TEST_RESULT_OUTPUT_DIR}/**/*.xml"
}

def queueJestStage(stages, delegate) {
  queueTestStage(stages, delegate, 'tests-jest', []) {
    sh('build/new-jenkins/js/tests-jest.sh')
  }
}

def queueKarmaStage(stages, delegate, group, ciNode, ciTotal) {
  queueTestStage(stages, delegate, "tests-karma-${group}-${ciNode}", [
    "CI_NODE_INDEX=${ciNode}",
    "CI_NODE_TOTAL=${ciTotal}",
    "JSPEC_GROUP=${group}",
  ]) {
    sh('build/new-jenkins/js/tests-karma.sh')
  }
}

def queuePackagesStage(stages, delegate) {
  queueTestStage(stages, delegate, 'tests-packages', []) {
    sh('build/new-jenkins/js/tests-packages.sh')
  }
}

def queueTestStage(stages, delegate, containerName, additionalEnvVars, block) {
  def baseEnvVars = [
    "CONTAINER_NAME=${containerName}",
    "TEST_RESULT_OUTPUT_DIR=js-results/${containerName}",
  ]

  delegate.extendedStage(containerName)
    .envVars(baseEnvVars + additionalEnvVars)
    .hooks([onNodeReleasing: this.&tearDownNode])
    .obeysAllowStages(false)
    .queue(stages) { block() }
}
