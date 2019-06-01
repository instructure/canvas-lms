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

gems = [
  'analytics',
  'banner_grade_export_plugin',
  'canvas_geoip',
  'canvas_salesforce_plugin',
  'canvas_webhooks',
  'canvas_zendesk_plugin',
  'canvasnet_registration',
  'catalog_provisioner',
  'custom_reports',
  'demo_site',
  'ims_es_importer_plugin',
  'instructure_misc_plugin',
  'migration_tool',
  'multiple_root_accounts',
  'phone_home_plugin',
  'respondus_lockdown_browser',
  'uuid_provisioner'
]

def withGerritCredentials = { Closure command ->
  withCredentials([
    sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')
  ]) { command() }
}

def fetchFromGerrit = { String repo, String path, String customRepoDestination = null, String sourcePath = null ->
  withGerritCredentials({ ->
    sh """
      mkdir -p ${path}/${customRepoDestination ?: repo}
      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
        git archive --remote=ssh://$GERRIT_URL/${repo} master ${sourcePath == null ? '' : sourcePath} | tar -x -v -C ${path}/${customRepoDestination ?: repo}
    """
  })
}

pipeline {
  agent { label 'docker' }

  options {
    ansiColor('xterm')
    parallelsAlwaysFailFast()
  }

  environment {
    COMPOSE_FILE = 'docker-compose.new-jenkins.yml'
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    // 'refs/changes/63/181863/8' -> '63.181863.8'
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
    PATCHSET_TAG = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$NAME"
    MERGE_TAG = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$GERRIT_BRANCH"
  }

  stages {
    stage('Debug') {
      steps {
        timeout(time: 20, unit: 'SECONDS') {
          sh 'printenv | sort'
        }
      }
    }

    stage('Plugins and Config Files') {
      steps {
        timeout(time: 3) {
          script {
            /* send message to gerrit */
            withGerritCredentials({ ->
              sh '''
                gerrit_message="\u2615 $JOB_BASE_NAME build started.\nTag: canvas-lms:$NAME\n$BUILD_URL"
                ssh -i "$SSH_KEY_PATH" -l "$SSH_USERNAME" -p $GERRIT_PORT \
                  hudson@$GERRIT_HOST gerrit review -m "'$gerrit_message'" $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER
              '''
            })

            /* fetch plugins */
            gems.each { gem -> fetchFromGerrit(gem, 'gems/plugins') }
            fetchFromGerrit('qti_migration_tool', 'vendor', 'QTIMigrationTool')
            fetchFromGerrit('gerrit_builder', '.', '', 'canvas-lms/config')
            sh '''
              mv gerrit_builder/canvas-lms/config/* config/
              rmdir -p gerrit_builder/canvas-lms/config
              cp docker-compose/config/selenium.yml config/
            '''
          }
        }
      }
    }

    stage('Rebase') {
      when { expression { env.GERRIT_EVENT_TYPE == 'patchset-created' } }
      steps {
        timeout(time: 2) {
          sh '''
            git config user.name $GERRIT_EVENT_ACCOUNT_NAME
            git config user.email $GERRIT_EVENT_ACCOUNT_EMAIL
            git rebase --preserve-merges origin/$GERRIT_BRANCH
            rebase_exit_code="$?"
            if [ $rebase_exit_code != 0 ]; then
              echo "Warning: Rebase couldn't resolve changes automatically, please resolve these conflicts locally."
              git rebase --abort
            fi
          '''
        }
      }
    }

    stage('Build Image') {
      steps {
        timeout(time: 36) { /* this timeout is `2 * average build time` which currently: 18m * 2 = 36m */
          sh 'docker build -t $PATCHSET_TAG .'
        }
      }
    }

    stage('Smoke Test') {
      steps {
        timeout(time: 10) {
          sh 'build/new-jenkins/smoke-test.sh'
        }
      }
    }

    stage('Publish Image') {
      steps {
        timeout(time: 5) {
          script {
            // always push the patchset tag otherwise when a later
            // patchset is merged this patchset tag is overwritten
            sh 'docker push $PATCHSET_TAG'

            if (env.GERRIT_EVENT_TYPE == 'change-merged') {
              sh '''
                docker tag $PATCHSET_TAG $MERGE_TAG
                docker push $MERGE_TAG
              '''
            }
          }
        }
      }
    }
  }

  post {
    success {
      script {
        withGerritCredentials({ ->
          sh '''
            gerrit_message="\u2713 $JOB_BASE_NAME build successful.\nTag: canvas-lms:$NAME\n$BUILD_URL"
            ssh -i "$SSH_KEY_PATH" -l "$SSH_USERNAME" -p $GERRIT_PORT \
              hudson@$GERRIT_HOST gerrit review -m "'$gerrit_message'" $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER
          '''
        })
      }
    }

    unsuccessful {
      script {
        withGerritCredentials({ ->
          sh '''
            gerrit_message="\u274C $JOB_BASE_NAME build failed.\nTag: canvas-lms:$NAME\n$BUILD_URL"
            ssh -i "$SSH_KEY_PATH" -l "$SSH_USERNAME" -p $GERRIT_PORT \
              hudson@$GERRIT_HOST gerrit review -m "'$gerrit_message'" $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER
          '''
        })
      }
    }

    cleanup {
      script {
        sh 'docker-compose down --volumes --rmi local'
      }
    }
  }
}
