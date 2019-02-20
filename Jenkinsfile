#!/usr/bin/env groovy

def gems = [
  'analytics', 'banner_grade_export_plugin', 'canvas_geoip', 'canvas_salesforce_plugin', 'canvas_webhooks',
  'canvas_zendesk_plugin', 'canvasnet_registration', 'catalog_provisioner', 'custom_reports', 'demo_site',
  'ims_es_importer_plugin', 'instructure_misc_plugin', 'migration_tool', 'multiple_root_accounts',
  'phone_home_plugin', 'respondus_lockdown_browser', 'uuid_provisioner'
]

def fetchFromGerrit = { String repo, String path, String customRepoDestination = null ->
  withCredentials([sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')]) {
  sh """
    mkdir -p ${path}/${customRepoDestination ?: repo}
    GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
      git archive --remote=ssh://$GERRIT_URL/${repo} master | tar -x -C ${path}/${customRepoDestination ?: repo}
  """
  }
}

def fetchGems = gems.collectEntries { String gem ->
  [ "${gem}" : { fetchFromGerrit(gem, 'gems/plugins') } ]
}

pipeline {
  agent { label 'docker' }

  options {
    ansiColor('xterm')
    parallelsAlwaysFailFast()
  }

  environment {
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
    IMAGE_TAG = "$DOCKER_REGISTRY_FQDN/canvas-lms:$NAME"
    GERRIT_PORT = "29418"
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
  }

  stages {

    stage('Other Project Dependencies') {
      parallel {

        stage('Gems') {
          steps { script { parallel fetchGems } }
        }

        stage('Vendor QTI Migration Tool') {
          steps {
            script {
              withCredentials([sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')]) {
              sh """
                mkdir -p vendor/QTIMigrationTool
                GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                  git archive --remote=ssh://$GERRIT_URL/qti_migration_tool master | tar -x -C vendor/QTIMigrationTool
              """
              }
            }
          }
        }

        stage('Config Files') {
          steps {
            script {
              withCredentials([sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')]) {
                sh """
                  GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                    git archive --remote=ssh://$GERRIT_URL/gerrit_builder master canvas-lms/config | tar -x -C config
                """
              }
            }
          }
        }
      }
    }

    stage('Build Image') {
      steps {
        timeout(time: 20, unit: 'MINUTES') {
          sh 'docker build -t $IMAGE_TAG .'
        }
      }
    }

    /*
    stage('Publish Image') {
      when { environment name: 'GERRIT_EVENT_TYPE', value: 'change-merged' }
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sh 'docker push $IMAGE_TAG'
        }
      }
    }
    */
  }
}
