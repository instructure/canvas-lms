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

def COFFEE_NODE_COUNT = 1
def DEFAULT_NODE_COUNT = 1
def JSG_NODE_COUNT = 3

def copyFiles(dockerName, dockerPath, hostPath) {
  sh "mkdir -vp ./$hostPath"
  sh "docker cp \$(docker ps -qa -f name=$dockerName):/usr/src/app/$dockerPath ./$hostPath"
}

def makeKarmaStage(group, ciNode, ciTotal) {
  return {
    withEnv([
      "CI_NODE_INDEX=${ciNode}",
      "CI_NODE_TOTAL=${ciTotal}",
      "CONTAINER_NAME=tests-karma-${group}-${ciNode}",
      "JSPEC_GROUP=${group}"
    ]) {
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

def cleanupFn() {
  timeout(time: 5) {
    try {
      archiveArtifacts artifacts: 'tmp/**/*.xml'
      junit "tmp/**/*.xml"
      sh 'find ./tmp -path "*.xml"'
    } finally {
      execute 'bash/docker-cleanup.sh --allow-failure'
    }
  }
}

pipeline {
  agent none
  options { ansiColor('xterm') }

  environment {
    COMPOSE_FILE = 'docker-compose.new-jenkins.canvas.yml:docker-compose.new-jenkins-karma.yml'
    FORCE_FAILURE = configuration.forceFailureJS()
    SENTRY_URL="https://sentry.insops.net"
    SENTRY_ORG="instructure"
    SENTRY_PROJECT="master-javascript-build"
  }

  stages {
    stage('Environment') {
      steps {
        script {
          protectedNode('canvas-docker', { cleanupFn() }) {
            stage('Setup') {
              cleanAndSetup()
              timeout(time: 10) {
                sh 'rm -vrf ./tmp/*'
                checkout scm
                sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $PATCHSET_TAG'
                sh 'docker-compose build'
              }
            }

            stage('Run Tests') {
              timeout(time: 60) {
                script {
                  def tests = [:]

                  if(env.TEST_SUITE == 'jest') {
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
                  }

                  if(env.TEST_SUITE == 'karma') {
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

                    for(int i = 0; i < COFFEE_NODE_COUNT; i++) {
                      tests["Karma - Spec Group - coffee${i}"] = makeKarmaStage('coffee', i, COFFEE_NODE_COUNT)
                    }

                    for(int i = 0; i < JSG_NODE_COUNT; i++) {
                      tests["Karma - Spec Group - jsg${i}"] = makeKarmaStage('jsg', i, JSG_NODE_COUNT)
                    }

                    ['jsa', 'jsh'].each { group ->
                      tests["Karma - Spec Group - ${group}"] = makeKarmaStage(group, 0, DEFAULT_NODE_COUNT)
                    }
                  }

                  parallel(tests)
                }
              }
            }
          }
        }
      }
    }
  }
}
