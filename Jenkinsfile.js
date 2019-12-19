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

def isMerge () {
  return env.GERRIT_EVENT_TYPE == 'change-merged'
}

pipeline {
  agent { label 'canvas-docker' }
  options {
    ansiColor('xterm')
  }

  environment {
    COMPOSE_FILE = 'docker-compose.new-jenkins-web.yml:docker-compose.new-jenkins-karma.yml'

    // 'refs/changes/63/181863/8' -> '63.181863.8'
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
    PATCHSET_TAG = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$NAME"
  }
  stages {
    stage('Pre-Cleanup') {
      steps {
        timeout(time: 2) {
          sh 'build/new-jenkins/docker-cleanup.sh'
        }
      }
    }
    stage('Tests Setup') {
      steps {
        timeout(time: 60) {
          echo 'Running containers'
          sh 'docker ps'
          sh 'printenv | sort'
          sh 'build/new-jenkins/docker-compose-pull.sh'
          sh 'build/new-jenkins/docker-compose-build-up.sh'
        }
      }
    }
    stage('Tests') {
      environment {
        COVERAGE = isMerge()
      }
      parallel {
        stage('Jest') {
          steps {
            sh 'build/new-jenkins/js/tests-jest.sh'
          }
        }
        stage('Packages') {
          steps {
            sh 'build/new-jenkins/js/tests-packages.sh'
          }
        }
        stage('canvas_quizzes') {
          steps {
            sh 'build/new-jenkins/js/tests-quizzes.sh'
          }
        }
        stage('Karma - Spec Group - coffee') {
          environment {
            JSPEC_GROUP = 'coffee'
          }
          steps {
            sh 'build/new-jenkins/js/tests-karma.sh'
          }
        }
        stage('Karma - Spec Group - jsa - A-F') {
          environment {
            JSPEC_GROUP = 'jsa'
          }
          steps {
            sh 'build/new-jenkins/js/tests-karma.sh'
          }
        }
        stage('Karma - Spec Group - jsg - G') {
          environment {
            JSPEC_GROUP = 'jsg'
          }
          steps {
            sh 'build/new-jenkins/js/tests-karma.sh'
          }
        }
        stage('Karma - Spec Group - jsh - H-Z') {
          environment {
            JSPEC_GROUP = 'jsh'
          }
          steps {
            sh 'build/new-jenkins/js/tests-karma.sh'
          }
        }
      }
    }
  }
  post {
    cleanup {
      sh 'build/new-jenkins/docker-cleanup.sh --allow-failure'
    }
  }
}
