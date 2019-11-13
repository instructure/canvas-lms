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

def withGerritCredentials = { Closure command ->
  withCredentials([
    sshUserPrivateKey(credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USERNAME')
  ]) { command() }
}

def fetchFromGerrit = { String repo, String path, String customRepoDestination = null, String sourcePath = null, String sourceRef = null ->
  withGerritCredentials({ ->
    println "Fetching ${repo} plugin"
    sh """
      mkdir -p ${path}/${customRepoDestination ?: repo}
      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
        git archive --remote=ssh://$GERRIT_URL/${repo} ${sourceRef == null ? 'master' : sourceRef} ${sourcePath == null ? '' : sourcePath} | tar -x -C ${path}/${customRepoDestination ?: repo}
    """
  })
}

def fullSuccessName(name) {
  return "_successes/${env.GERRIT_CHANGE_NUMBER}-${env.GERRIT_PATCHSET_NUMBER}-${name}-success"
}

def hasSuccess(name) {
  copyArtifacts(filter: "_successes/*",
                optional: true,
                projectName: '/${JOB_NAME}',
                parameters: "GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER},GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER}",
                selector: lastCompleted())
  if (fileExists("_successes")) {
    archiveArtifacts(artifacts: "_successes/*",
                    projectName: '/${JOB_NAME}')
  }
  return fileExists(fullSuccessName(name))
}

def saveSuccess(name) {
  def success_name = fullSuccessName(name)
  sh "mkdir -p _successes"
  sh "echo 'success' >> ${success_name}"
  archiveArtifacts(artifacts: "_successes/*",
                   projectName: '/${JOB_NAME}')
  echo "===> success saved /${env.JOB_NAME}: ${success_name}"
}

// runs the body if it has not previously succeeded.
// if you don't want the success of the body to mark the
// given name as successful, pass in save = false.
def skipIfPreviouslySuccessful(name, save = true, body) {
  if (hasSuccess(name)) {
    echo "===> block already successful, skipping: ${fullSuccessName(name)}"
  } else {
    echo "===> running block: ${fullSuccessName(name)}"
    body.call()
    if (save) saveSuccess(name)
  }
}

def build_parameters = [
  string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
  string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
  string(name: 'GERRIT_BRANCH', value: "${env.GERRIT_BRANCH}"),
  string(name: 'GERRIT_CHANGE_NUMBER', value: "${env.GERRIT_CHANGE_NUMBER}"),
  string(name: 'GERRIT_PATCHSET_NUMBER', value: "${env.GERRIT_PATCHSET_NUMBER}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_NAME', value: "${env.GERRIT_EVENT_ACCOUNT_NAME}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_EMAIL', value: "${env.GERRIT_EVENT_ACCOUNT_EMAIL}")
]

pipeline {
  agent { label 'canvas-docker' }

  options {
    ansiColor('xterm')
  }

  environment {
    // include selenium while smoke is running locally
    COMPOSE_FILE = 'docker-compose.new-jenkins.yml:docker-compose.new-jenkins-selenium.yml'
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"

    // 'refs/changes/63/181863/8' -> '63.181863.8'
    NAME = "${env.GERRIT_REFSPEC}".minus('refs/changes/').replaceAll('/','.')
    PATCHSET_TAG = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$NAME"
    MERGE_TAG = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms:$GERRIT_BRANCH"
    CACHE_TAG = "canvas-lms:previous-image"
  }

  stages {
    stage('Print Env Variables') {
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
            fetchFromGerrit('gerrit_builder', '.', '', 'canvas-lms/config')
            gems = readFile('gerrit_builder/canvas-lms/config/plugins_list').split()
            println "Plugin list: ${gems}"
            /* fetch plugins */
            gems.each { gem ->
              if (env.GERRIT_PROJECT == gem) {
                /* this is the commit we're testing */
                fetchFromGerrit(gem, 'gems/plugins', null, null, env.GERRIT_REFSPEC)
              } else {
                fetchFromGerrit(gem, 'gems/plugins')
              }
            }
            fetchFromGerrit('qti_migration_tool', 'vendor', 'QTIMigrationTool')
            sh '''
              mv gerrit_builder/canvas-lms/config/* config/
              mv config/knapsack_rspec_report.json ./
              rm config/cache_store.yml
              rmdir -p gerrit_builder/canvas-lms/config
              cp docker-compose/config/selenium.yml config/
              cp -R docker-compose/config/new-jenkins config/new-jenkins
              cp config/delayed_jobs.yml.example config/delayed_jobs.yml
              cp config/domain.yml.example config/domain.yml
              cp config/external_migration.yml.example config/external_migration.yml
              cp config/outgoing_mail.yml.example config/outgoing_mail.yml
            '''
          }
        }
      }
    }

    stage('Rebase') {
      when { expression { env.GERRIT_EVENT_TYPE == 'patchset-created' } }
      steps {
        timeout(time: 2) {
          script {
            withGerritCredentials({ ->
              sh '''
                GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                  git fetch origin $GERRIT_BRANCH

                git config user.name "$GERRIT_EVENT_ACCOUNT_NAME"
                git config user.email "$GERRIT_EVENT_ACCOUNT_EMAIL"

                # this helps current build issues where cleanup is needed before proceeding.
                # however the later git rebase --abort should be enough once this has
                # been on jenkins for long enough to hit all nodes, maybe a couple days?
                if [ -d .git/rebase-merge ]; then
                  echo "A previous build's rebase failed and the build exited without cleaning up. Aborting the previous rebase now..."
                  git rebase --abort
                  git checkout $GERRIT_REFSPEC
                fi

                # store exit_status inline to  ensures the script doesn't exit here on failures
                git rebase --preserve-merges origin/$GERRIT_BRANCH; exit_status=$?
                if [ $exit_status != 0 ]; then
                  echo "Warning: Rebase couldn't resolve changes automatically, please resolve these conflicts locally."
                  git rebase --abort
                  exit $exit_status
                fi
              '''
            })
          }
        }
      }
    }

    stage('Build Image') {
      steps {
        skipIfPreviouslySuccessful("build-and-push-image", save = false) {
          timeout(time: 36) { /* this timeout is `2 * average build time` which currently: 18m * 2 = 36m */
            dockerCacheLoad(image: "$CACHE_TAG")
            sh '''
              docker build -t $PATCHSET_TAG .
              docker tag $PATCHSET_TAG $CACHE_TAG
            '''
          }
        }
      }
    }

    stage('Publish Patchset Image') {
      steps {
        skipIfPreviouslySuccessful("build-and-push-image") {
          timeout(time: 5) {
            // always push the patchset tag otherwise when a later
            // patchset is merged this patchset tag is overwritten
            sh 'docker push $PATCHSET_TAG'
          }
        }
      }
    }

    stage('Parallel Run Tests') {
      parallel {
        // TODO: this is temporary until we can get some actual builds passing
        stage('Smoke Test') {
          steps {
            skipIfPreviouslySuccessful("smoke-test") {
              timeout(time: 10) {
                sh 'build/new-jenkins/docker-compose-pull.sh'
                sh 'build/new-jenkins/docker-compose-pull-selenium.sh'
                sh 'build/new-jenkins/docker-compose-build-up.sh'
                sh 'build/new-jenkins/docker-compose-create-migrate-database.sh'
                sh 'build/new-jenkins/smoke-test.sh'
              }
            }
          }
        }

        stage('Vendored Gems') {
          steps {
            skipIfPreviouslySuccessful("vendored-gems") {
              build(
                job: 'test-suites/vendored-gems',
                parameters: build_parameters
              )
            }
          }
        }
/*
 *  Don't run these on all patch sets until we have them ready to report results.
 *  Uncomment stage to run when developing.
 *       stage('Selenium Chrome') {
 *         steps {
 *           skipIfPreviouslySuccessful("selenium-chrome") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/selenium-chrome',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 *
 *       stage('Rspec') {
 *         steps {
 *           skipIfPreviouslySuccessful("rspec") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/rspec',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 *
 *       stage('Selenium Performance Chrome') {
 *         steps {
 *           skipIfPreviouslySuccessful("selenium-performance-chrome") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/selenium-performance-chrome',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 *
 *       stage('Contract Tests') {
 *         steps {
 *           skipIfPreviouslySuccessful("contract-tests") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/contract-tests',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 *
 *       stage('Frontend') {
 *         steps {
 *           skipIfPreviouslySuccessful("frontend") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/frontend',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 *
 *      stage('Linters') {
 *        steps {
 *          skipIfPreviouslySuccessful("linters") {
 *            build(
 *              job: 'test-suites/linters',
 *              parameters: build_parameters
 *            )
 *          }
 *        }
 *      }
 *
 *       stage('Xbrowser') {
 *         steps {
 *           skipIfPreviouslySuccessful("xbrowser") {
 *             // propagate set to false until we can get tests passing
 *             build(
 *               job: 'test-suites/xbrowser',
 *               propagate: false,
 *               parameters: build_parameters
 *             )
 *           }
 *         }
 *       }
 */
      }
    }

    stage('Publish Merged Image') {
      steps {
        timeout(time: 5) {
          script {
            if (env.GERRIT_EVENT_TYPE == 'change-merged') {
              sh '''
                docker tag $PATCHSET_TAG $MERGE_TAG
                docker push $MERGE_TAG
              '''
              dockerCacheStore(image: "$CACHE_TAG")
            }
          }
        }
      }
    }
  }

  post {
    cleanup {
        sh 'build/new-jenkins/docker-cleanup.sh'
    }
  }
}
