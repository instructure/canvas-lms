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

def runCoverage() {
  def flags = load 'build/new-jenkins/groovy/commit-flags.groovy'
  return env.RUN_COVERAGE == '1' || flags.forceRunCoverage() ? '1' : ''
}

def isForceFailure() {
  def flags = load 'build/new-jenkins/groovy/commit-flags.groovy'
  return flags.isForceFailure() ? "1" : ''
}

def getImageTagVersion() {
  def flags = load 'build/new-jenkins/groovy/commit-flags.groovy'
  // total hack, we shouldnt do it like this. but until there is a better
  // way of passing info across builds, this is path of least resistance..
  // also, it didnt seem to work with multiple return statements, so i'll
  // just go ahead and leave this monstrosity here.
  return env.RUN_COVERAGE == '1' ? 'master' : flags.getImageTagVersion()
}

def copyFiles(docker_name, docker_dir, host_dir) {
  sh "mkdir -vp ./$host_dir"
  sh "docker cp \$(docker ps -qa -f name=$docker_name):/usr/src/app/$docker_dir ./$host_dir"
}

def withSentry(block) {
  def credentials = load 'build/new-jenkins/groovy/credentials.groovy'
  credentials.withSentryCredentials(block)
}

def runInSeriesOrParallel(is_series, stages_map) {
  if (is_series) {
    echo "running tests in series: ${stages_map.keys}"
    stages_map.each { name, block ->
      stage(name) {
        block()
      }
    }
  }
  else {
    echo "running tests in parallel: ${stages_map.keys}"
    parallel(stages_map)
  }
}

pipeline {
  agent { label 'canvas-docker' }
  options { ansiColor('xterm') }

  environment {
    COMPOSE_FILE = 'docker-compose.new-jenkins-web.yml:docker-compose.new-jenkins-karma.yml'
    COVERAGE = runCoverage()
    FORCE_FAILURE = isForceFailure()
    SENTRY_URL="https://sentry.insops.net"
    SENTRY_ORG="instructure"
    SENTRY_PROJECT="master-javascript-build"
  }

  stages {
    stage('Pre-Cleanup') {
      steps {
        timeout(time: 2) {
          sh 'build/new-jenkins/docker-cleanup.sh'
          sh 'build/new-jenkins/print-env-excluding-secrets.sh'
          sh 'rm -vrf ./tmp/*'
        }
      }
    }

    stage('Tests Setup') {
      steps {
        timeout(time: 60) {
          sh 'build/new-jenkins/docker-compose-pull.sh'
          sh 'docker-compose build'
        }
      }
    }

    stage('Test Stage Coordinator') {
      steps {
        script {
          def tests = [:]

          tests['Jest'] = {
            withEnv(['CONTAINER_NAME=tests-jest']) {
              try {
                withSentry {
                  sh 'build/new-jenkins/js/tests-jest.sh'
                }
                if (env.COVERAGE == '1') {
                  copyFiles(env.CONTAINER_NAME, 'coverage-jest', "./tmp/${env.CONTAINER_NAME}-coverage")
                }
              }
              finally {
                copyFiles(env.CONTAINER_NAME, 'coverage-js', "./tmp/${env.CONTAINER_NAME}")
              }
            }
          }

          tests['Packages'] = {
            withEnv(['CONTAINER_NAME=tests-packages']) {
              try {
                withSentry {
                  sh 'build/new-jenkins/js/tests-packages.sh'
                }
              }
              finally {
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
                  withSentry {
                    sh 'build/new-jenkins/js/tests-karma.sh'
                  }
                  if (env.COVERAGE == '1') {
                    copyFiles(env.CONTAINER_NAME, 'coverage-karma', "./tmp/${env.CONTAINER_NAME}-coverage")
                  }
                }
                finally {
                  copyFiles(env.CONTAINER_NAME, 'coverage-js', "./tmp/${env.CONTAINER_NAME}")
                }
              }
            }
          }

          runInSeriesOrParallel(env.COVERAGE == '1', tests)
        }
      }
    }


    stage('Upload Coverage') {
      when { expression { env.COVERAGE == '1' } }
      steps {
        timeout(time: 10) {
          sh 'build/new-jenkins/js/coverage-report.sh'
          archiveArtifacts(artifacts: 'coverage-report-js/**/*')
          uploadCoverage([
              uploadSource: "/coverage-report-js/report-html",
              uploadDest: "canvas-lms-js/coverage"
          ])
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
      sh 'build/new-jenkins/docker-cleanup.sh --allow-failure'
    }
  }
}
