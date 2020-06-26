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

library "canvas-builds-library"

def copyFiles(dockerName, dockerPath, hostPath) {
  sh "mkdir -vp ./$hostPath"
  sh "docker cp \$(docker ps -qa -f name=$dockerName):/usr/src/app/$dockerPath ./$hostPath"
}

pipeline {
  agent { label 'canvas-docker' }
  options { ansiColor('xterm') }

  environment {
    COMPOSE_FILE = 'docker-compose.new-jenkins.canvas.yml:docker-compose.new-jenkins-karma.yml'
    FORCE_FAILURE = configuration.forceFailureJS()
    SENTRY_URL="https://sentry.insops.net"
    SENTRY_ORG="instructure"
    SENTRY_PROJECT="master-javascript-build"
  }

  stages {
    stage('Setup') {
      steps {
        cleanAndSetup()
        timeout(time: 10) {
          sh 'rm -vrf ./tmp/*'
          sh 'docker pull $PATCHSET_TAG'
          sh 'docker-compose build'
        }
      }
    }

    stage('Test Stage Coordinator') {
      steps {
        timeout(time: 60) {
          script {
            def tests = [:]

            tests['Jest'] = {
              withEnv(['CONTAINER_NAME=tests-jest']) {
                try {
                  credentials.withSentryCredentials {
                    sh 'build/new-jenkins/js/tests-jest.sh'
                  }
                } finally {
                  copyFiles(env.CONTAINER_NAME, 'coverage-js', "./tmp/${env.CONTAINER_NAME}")
                }
              }
            }

            tests['Packages'] = {
              withEnv(['CONTAINER_NAME=tests-packages']) {
                try {
                  credentials.withSentryCredentials {
                    sh 'build/new-jenkins/js/tests-packages.sh'
                  }
                } finally {
                  copyFiles(env.CONTAINER_NAME, 'packages', "./tmp/${env.CONTAINER_NAME}")
                }
              }
            }

            tests['canvas_quizzes'] = {
              sh 'build/new-jenkins/js/tests-quizzes.sh'
            }

            ['coffee', 'jsa', 'jsg', 'jsh'].each { group ->
              tests["Karma - Spec Group - ${group}"] = {
                withEnv(["CONTAINER_NAME=tests-karma-${group}", "JSPEC_GROUP=${group}"]) {
                  try {
                    credentials.withSentryCredentials {
                      sh 'build/new-jenkins/js/tests-karma.sh'
                    }
                  } finally {
                    copyFiles(env.CONTAINER_NAME, 'coverage-js', "./tmp/${env.CONTAINER_NAME}")
                  }
                }
              }
            }

            parallel(tests)
          }
        }
      }
    }
  }

  post {
    always {
      script {
        junit allowEmptyResults: true, testResults: 'tmp/**/*.xml'
        sh 'find ./tmp -path "*.xml"'
      }
    }
    cleanup {
      execute 'bash/docker-cleanup.sh --allow-failure'
    }
  }
}
