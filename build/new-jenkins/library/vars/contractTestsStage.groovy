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

def setupNode() {
  def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.GERRIT_REFSPEC : env.CANVAS_LMS_REFSPEC
  checkoutFromGit(gerritProjectUrl('canvas-lms'), refspec: refspecToCheckout, depth: 1)
  libraryScript.load('bash/docker-with-flakey-network-protection.sh', './docker-with-flakey-network-protection.sh')

  // Pull required images with network protection
  sh './docker-with-flakey-network-protection.sh pull $PATCHSET_TAG'
  sh './docker-with-flakey-network-protection.sh pull $POSTGRES_IMAGE_TAG'
  sh './docker-with-flakey-network-protection.sh pull $DYNAMODB_IMAGE_TAG'

  // Start postgres and dynamodb services
  sh "docker compose -f ${env.COMPOSE_FILE} up -d"

  // Wait for postgres to be ready
  sh """
    timeout 60 bash -c 'until docker compose -f ${env.COMPOSE_FILE} exec -T postgres pg_isready -U postgres; do sleep 1; done'
  """
}

def createDatabase(databaseName) {
  sh """
    docker compose -f ${env.COMPOSE_FILE} exec -T postgres createdb -U postgres -T canvas_test ${databaseName}
  """
}

def tearDownNode() {
  pipelineHelpers.copyFromContainer('canvas', '/usr/src/app/log/results/', './log/results')
  junit 'log/results/**/*.xml'
}

@SuppressWarnings('ParameterCount')
def runContractTest(stageName, databaseName, consumerName, envVars, command, allocateNode = true) {
  def baseEnvVars = [
    "DATABASE_NAME=${databaseName}",
    "DATABASE_URL=postgres://postgres:${env.POSTGRES_PASSWORD}@postgres:5432/${databaseName}",
    "PACT_API_CONSUMER=${consumerName}",
  ]

  def allEnvVars = baseEnvVars + envVars
  def envFlags = allEnvVars.collect { "-e ${it}" }.join(' ')

  def executeTest = {
    def startTime = System.currentTimeMillis()
    try {
      stage("${stageName} - Cleanup") {
        pipelineHelpers.cleanupWorkspace()
      }

      stage("${stageName} - Setup") {
        setupNode()
      }

      stage("${stageName} - Create DB") {
        createDatabase(databaseName)
      }

      stage("${stageName} - Run Tests") {
        try {
          sh "docker compose -f ${env.COMPOSE_FILE} exec -T ${envFlags} canvas bash -c '${command}'"
        } finally {
          tearDownNode()
          buildSummaryReport.trackStage(stageName, startTime)
        }
      }
    } finally {
      pipelineHelpers.cleanupDocker()
    }
  }

  // If allocateNode is false, run on current agent. Otherwise allocate new node.
  if (!allocateNode) {
    executeTest()
  } else {
    node(nodeLabel()) {
      executeTest()
    }
  }
}

return this
