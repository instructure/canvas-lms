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
    sh(script: 'build/new-jenkins/docker-compose-pull.sh', label: 'Pull Images')
  }

  sh 'build/new-jenkins/pact/docker-compose-pact-setup.sh'
}

def tearDownNode() {
  { ->
    sh "build/new-jenkins/docker-copy-files.sh /usr/src/app/log/results/ tmp/spec_results/${DATABASE_NAME} ${DATABASE_NAME} --allow-error --clean-dir"
    junit "tmp/spec_results/${DATABASE_NAME}/**/*.xml"
  }
}

def queueTestStage(stageName) {
  { opts, stages ->
    def baseEnvVars = [
      "DATABASE_NAME=${opts.databaseName}",
      "PACT_API_CONSUMER=${opts.containsKey('consumerName') ? opts.consumerName : ''}",
    ]

    def additionalEnvVars = opts.containsKey('envVars') ? opts.envVars : []

    extendedStage(stageName)
      .envVars(baseEnvVars + additionalEnvVars)
      .hooks([onNodeReleasing: this.tearDownNode()])
      .obeysAllowStages(false)
      .queue(stages) { sh(opts.command) }
  }
}

return this
