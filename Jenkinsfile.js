#!/usr/bin/env groovy

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

pipeline {
  agent none
  options {
    ansiColor('xterm')
    timeout(time: 20)
    timestamps()
  }

  environment {
    BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
    COMPOSE_DOCKER_CLI_BUILD = 1
    COMPOSE_FILE = 'docker-compose.new-jenkins-js.yml'
    DOCKER_BUILDKIT = 1
    FORCE_FAILURE = configuration.forceFailureJS()
    PROGRESS_NO_TRUNC = 1
  }

  stages {
    stage('Environment') {
      steps {
        script {
          def runnerStages = [:]

          for (int i = 0; i < jsStage.JEST_NODE_COUNT; i++) {
            String index = i
            extendedStage("Runner - Jest ${i}").nodeRequirements(label: 'canvas-docker', podTemplate: jsStage.jestNodeRequirementsTemplate(index)).obeysAllowStages(false).timeout(10).queue(runnerStages) {
              def tests = [:]

              callableWithDelegate(jsStage.queueJestDistribution(index))(tests)

              parallel(tests)
            }
          }

          extendedStage('Runner - Coffee').nodeRequirements(label: 'canvas-docker', podTemplate: jsStage.coffeeNodeRequirementsTemplate()).obeysAllowStages(false).timeout(10).queue(runnerStages) {
            def tests = [:]

            callableWithDelegate(jsStage.queueCoffeeDistribution())(tests)

            parallel(tests)
          }

          extendedStage('Runner - Karma').nodeRequirements(label: 'canvas-docker', podTemplate: jsStage.karmaNodeRequirementsTemplate()).obeysAllowStages(false).timeout(10).queue(runnerStages) {
            def tests = [:]

            callableWithDelegate(jsStage.queueKarmaDistribution())(tests)

            parallel(tests)
          }

          parallel(runnerStages)
        }
      }
    }
  }
}
