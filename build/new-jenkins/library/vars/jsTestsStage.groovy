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

import groovy.transform.Field

@Field final static VITEST_NODE_COUNT = 16

def checkoutCode() {
  def refspecToCheckout = env.GERRIT_PROJECT == 'canvas-lms' ? env.GERRIT_REFSPEC : env.CANVAS_LMS_REFSPEC
  checkoutFromGit(gerritProjectUrl('canvas-lms'), refspec: refspecToCheckout, depth: 1)
}

def provisionDocker() {
  libraryScript.load('bash/docker-with-flakey-network-protection.sh', './docker-with-flakey-network-protection.sh')
  libraryScript.load('js/docker-provision.sh', './docker-provision.sh')
  sh('./docker-provision.sh')
}

def startServices() {
  sh("docker compose -f ${env.COMPOSE_FILE} up -d")
}

def collectCoverage(stageName) {
  // Run the collection script INSIDE the container
  sh """
    docker compose -f ${env.COMPOSE_FILE} exec -T canvas bash -c '
      rm -rf /usr/src/app/coverage-report-js
      mkdir -p /usr/src/app/coverage-report-js
      chmod -R 777 /usr/src/app/coverage-report-js

      counter=0
      for coverage_file in \$(find . -type d -name node_modules -prune -o -name "coverage*.json" -print); do
        new_file="/usr/src/app/coverage-report-js/coverage-${stageName}-\${counter}.json"
        cp "\$coverage_file" "\$new_file"
        ((counter=counter+1))
      done
    '
  """

  // Copy from container to host
  pipelineHelpers.copyFromContainer('canvas', '/usr/src/app/coverage-report-js', './coverage-report-js')
  archiveArtifacts allowEmptyArchive: true, artifacts: 'coverage-report-js/*'
}

def runVitestNode(index, additionalEnvVars = []) {
  def stageName = "Vitest ${index}"
  node(nodeLabel()) {
    def stageStartTime = System.currentTimeMillis()
    try {
      stage("${stageName} - Cleanup") {
        pipelineHelpers.cleanupWorkspace()
      }

      stage("${stageName} - Setup") {
        checkoutCode()
        provisionDocker()
        startServices()
      }

      def baseEnvVars = [
        "CI_NODE_INDEX=${index.toInteger() + 1}",
        "CI_NODE_TOTAL=${VITEST_NODE_COUNT}",
        "FORCE_FAILURE=${env.FORCE_FAILURE}",
        "RAILS_ENV=test",
        "TEST_RESULT_OUTPUT_DIR=js-results/vitest-${index}"
      ]
      def envVars = baseEnvVars + additionalEnvVars
      def envFlags = envVars.collect { "-e ${it}" }.join(' ')

      stage("${stageName} - Run Tests") {
        try {
          sh("docker compose -f ${env.COMPOSE_FILE} exec -T ${envFlags} canvas yarn test:build")
        } finally {
          buildSummaryReport.trackStage(stageName, stageStartTime)

          pipelineHelpers.copyFromContainer('canvas', "/usr/src/app/js-results/vitest-${index}", "./js-results/vitest-${index}")
          archiveArtifacts artifacts: "js-results/vitest-${index}/**/*.xml"
          junit "js-results/vitest-${index}/**/*.xml"

          if (env.COVERAGE == '1') {
            collectCoverage(stageName)
          }
        }
      }
    } finally {
      pipelineHelpers.cleanupDocker()
    }
  }
}

return this
