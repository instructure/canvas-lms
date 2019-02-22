#!/usr/bin/env groovy

def gems = [
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
  withCredentials([sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')]) {
    command('$SSH_KEY_PATH', '$SSH_USERNAME')
  }
}

def fetchFromGerrit = { String repo, String path, String customRepoDestination = null ->
  withGerritCredentials({ String SSH_KEY_PATH, String SSH_USER_NAME ->
    sh """
      mkdir -p ${path}/${customRepoDestination ?: repo}
      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
        git archive --remote=ssh://$GERRIT_URL/${repo} master | tar -x -C ${path}/${customRepoDestination ?: repo}
    """
  })
}

def fetchGems = gems.collectEntries { String gem ->
  [ "${gem}" : { fetchFromGerrit(gem, 'gems/plugins') } ]
}

def getImageTag() {
  //if (env.GERRIT_EVENT_TYPE == 'patchset-created') {
    // GERRIT__REFSPEC will be in the form 'refs/changes/63/181863/8'
    // we want a name in the form '63.181863.8'
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
    return "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$NAME"
  //} else {
  //  return "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$GERRIT_BRANCH"
  //}
}

pipeline {
  agent { label 'docker' }

  options {
    ansiColor('xterm')
    parallelsAlwaysFailFast()
  }

  environment {
    GERRIT_PORT = "29418"
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    IMAGE_TAG = getImageTag()
  }

  stages {
    stage('Debug') {
      steps {
        sh 'printenv | sort'
      }
    }

    stage('Other Project Dependencies') {
      parallel {

        stage('Gems') {
          steps { script { parallel fetchGems } }
        }

        stage('Vendor QTI Migration Tool') {
          steps {
            script {
              withGerritCredentials({ String SSH_KEY_PATH, String SSH_USER_NAME ->
                sh """
                  mkdir -p vendor/QTIMigrationTool
                  GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                    git archive --remote=ssh://$GERRIT_URL/qti_migration_tool master | tar -x -C vendor/QTIMigrationTool
                """
              })
            }
          }
        }

        stage('Config Files') {
          steps {
            script {
              withGerritCredentials({ String SSH_KEY_PATH, String SSH_USER_NAME ->
                sh """
                  GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                    git archive --remote=ssh://$GERRIT_URL/gerrit_builder master canvas-lms/config | tar -x -C config
                """
              })
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

    stage("Publish Image") {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          sh 'docker push $IMAGE_TAG'
        }
      }
    }
  }
}
