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

def buildParameters = [
  string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
  string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
  string(name: 'GERRIT_PROJECT', value: "${env.GERRIT_PROJECT}"),
  string(name: 'GERRIT_BRANCH', value: "${env.GERRIT_BRANCH}"),
  string(name: 'GERRIT_CHANGE_NUMBER', value: "${env.GERRIT_CHANGE_NUMBER}"),
  string(name: 'GERRIT_PATCHSET_NUMBER', value: "${env.GERRIT_PATCHSET_NUMBER}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_NAME', value: "${env.GERRIT_EVENT_ACCOUNT_NAME}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_EMAIL', value: "${env.GERRIT_EVENT_ACCOUNT_EMAIL}"),
  string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', value: "${env.GERRIT_CHANGE_COMMIT_MESSAGE}"),
  string(name: 'GERRIT_HOST', value: "${env.GERRIT_HOST}"),
  string(name: 'GERGICH_PUBLISH', value: "${env.GERGICH_PUBLISH}"),
  string(name: 'MASTER_BOUNCER_RUN', value: "${env.MASTER_BOUNCER_RUN}")
]

def getImageTagVersion() {
  def flags = load('build/new-jenkins/groovy/commit-flags.groovy')
  flags.getImageTagVersion()
}

def runBuildImageMaybe(block) {
  def flags = load('build/new-jenkins/groovy/commit-flags.groovy')
  if (flags.hasFlag('skip-docker-build')) {
    echo "Skip building image requested"
  } else {
    def successes = load('build/new-jenkins/groovy/successes.groovy')
    successes.skipIfPreviouslySuccessful("build-and-push-image", true, block)
  }
}

def skipIfPreviouslySuccessful(name, block) {
  def successes = load('build/new-jenkins/groovy/successes.groovy')
  successes.skipIfPreviouslySuccessful(name, true, block)
}

// ignore builds where the current patchset tag doesn't match the
// mainline publishable tag. i.e. ignore ruby-passenger-2.6/pg-12
// upgrade builds
def isPatchsetPublishable() {
  env.PATCHSET_TAG == env.PUBLISHABLE_TAG
}

// WARNING! total hack, being removed after covid...
def isCovid() {
  env.GERRIT_BRANCH == 'covid'
}
// end of hack (covid)

pipeline {
  agent { label 'canvas-docker' }
  options { ansiColor('xterm') }

  environment {
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    NAME = getImageTagVersion()
    CANVAS_LMS_IMAGE = "$DOCKER_REGISTRY_FQDN/jenkins/canvas-lms"

    // e.g. postgres-9.5-ruby-passenger-2.4-xenial
    TAG_SUFFIX = "postgres-$POSTGRES-ruby-passenger-$RUBY_PASSENGER"

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-passenger-2.6
    PATCHSET_TAG = "$CANVAS_LMS_IMAGE:$NAME-$TAG_SUFFIX"

    // e.g. canvas-lms:01.123456.78-postgres-9.5-ruby-passenger-2.4
    PUBLISHABLE_TAG = "$CANVAS_LMS_IMAGE:$NAME-postgres-9.5-ruby-passenger-2.4"

    // e.g. canvas-lms:master when not on another branch
    MERGE_TAG = "$CANVAS_LMS_IMAGE:$GERRIT_BRANCH"

    // e.g. canvas-lms:previous-image
    CACHE_TAG = "$CANVAS_LMS_IMAGE:previous-image"
  }

  stages {
    stage('Setup') {
      steps {
        timeout(time: 5) {
          script {
            sh 'build/new-jenkins/print-env-excluding-secrets.sh'
            sh 'build/new-jenkins/docker-cleanup.sh'

            buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
            buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
            buildParameters += string(name: 'RUBY_PASSENGER', value: "${env.RUBY_PASSENGER}")
            if (env.CANVAS_LMS_REFSPEC) {
              // the plugin builds require the canvas lms refspec to be different. so only
              // set this refspec if the main build is requesting it to be set.
              // NOTE: this is only being set in main-from-plugin build. so main-canvas wont run this.
              buildParameters += string(name: 'CANVAS_LMS_REFSPEC', value: env.CANVAS_LMS_REFSPEC)
            }

            def credentials = load ('build/new-jenkins/groovy/credentials.groovy')

            // WARNING! total hack, being removed after covid...
            // if this build is triggered from a plugin that is from the 
            // covid branch, we need to checkout the covid branch for canvas-lms
            if (isCovid() && env.GERRIT_PROJECT != 'canvas-lms') {
              echo 'checking out canvas-lms covid branch'
              credentials.withGerritCredentials {
                sh '''
                  set -ex
                  git branch -D covid || true
                  GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                    git fetch origin $GERRIT_BRANCH:origin/$GERRIT_BRANCH
                  git checkout -b covid origin/covid
                '''
              }
            }
            // end of hack (covid)

            credentials.fetchFromGerrit('gerrit_builder', '.', '', 'canvas-lms/config')
            gems = readFile('gerrit_builder/canvas-lms/config/plugins_list').split()
            echo "Plugin list: ${gems}"
            /* fetch plugins */
            gems.each { gem ->
              if (env.GERRIT_PROJECT == gem) {
                /* this is the commit we're testing */
                credentials.fetchFromGerrit(gem, 'gems/plugins', null, null, env.GERRIT_REFSPEC)
              } else {
                // WARNING! total hack, being removed after covid...
                // remove if statement when covid is done. only thing in else is needed.
                if (isCovid()) {
                  echo "checkin out ${gem} covid branch"
                  credentials.fetchFromGerrit(gem, 'gems/plugins', null, null, 'covid')
                }
                else {
                  credentials.fetchFromGerrit(gem, 'gems/plugins')
                }
                // end of hack (covid)
              }
            }
            credentials.fetchFromGerrit('gergich_user_config', '.')
            credentials.fetchFromGerrit('qti_migration_tool', 'vendor', 'QTIMigrationTool')

            sh 'mv -v gerrit_builder/canvas-lms/config/* config/'
            sh 'mv -v config/knapsack_rspec_report.json ./'
            sh 'rm -v config/cache_store.yml'
            sh 'rmdir -p gerrit_builder/canvas-lms/config'
            sh 'cp -v docker-compose/config/selenium.yml config/'
            sh 'cp -vR docker-compose/config/new-jenkins config/new-jenkins'
            sh 'cp -v config/delayed_jobs.yml.example config/delayed_jobs.yml'
            sh 'cp -v config/domain.yml.example config/domain.yml'
            sh 'cp -v config/external_migration.yml.example config/external_migration.yml'
            sh 'cp -v config/outgoing_mail.yml.example config/outgoing_mail.yml'
            sh 'cp -v ./gergich_user_config/gergich_user_config.yml ./gems/dr_diff/config/gergich_user_config.yml'
          }
        }
      }
    }

    stage('Rebase') {
      when { expression { env.GERRIT_EVENT_TYPE == 'patchset-created' && env.GERRIT_PROJECT == 'canvas-lms' } }
      steps {
        timeout(time: 2) {
          script {
            def credentials = load('build/new-jenkins/groovy/credentials.groovy')
            credentials.withGerritCredentials({ ->
              sh '''
                GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                  git fetch origin $GERRIT_BRANCH:origin/$GERRIT_BRANCH

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

    stage ('Build Docker Image') {
      steps {
        timeout(time: 36) { /* this timeout is `2 * average build time` which currently: 18m * 2 = 36m */
          runBuildImageMaybe() {
            script {
              def flags = load('build/new-jenkins/groovy/commit-flags.groovy')
              if (!flags.hasFlag('skip-cache')) {
                sh 'docker pull $CACHE_TAG || true'
              }
            }
            sh """
              docker build \
                --tag $PATCHSET_TAG \
                --build-arg RUBY_PASSENGER=$RUBY_PASSENGER \
                --build-arg POSTGRES_VERSION=$POSTGRES \
                .
            """
            sh "docker tag $PATCHSET_TAG $CACHE_TAG"

            sh "docker push $PATCHSET_TAG"
          }
        }
      }
    }

    stage('Parallel Run Tests') {
      parallel {
        stage('Linters') {
          when { expression { env.GERRIT_EVENT_TYPE != 'change-merged' && env.GERRIT_PROJECT == 'canvas-lms' } }
          steps {
            skipIfPreviouslySuccessful("linters") {
              script {
                sh 'build/new-jenkins/linters/run-gergich.sh'
                if (env.MASTER_BOUNCER_RUN == '1' && env.GERRIT_EVENT_TYPE == 'patchset-created') {
                  def credentials = load 'build/new-jenkins/groovy/credentials.groovy'
                  credentials.withMasterBouncerCredentials {
                    sh 'build/new-jenkins/linters/run-master-bouncer.sh'
                  }
                }
              }
            }
          }
        }

        stage('Vendored Gems') {
          steps {
            skipIfPreviouslySuccessful("vendored-gems") {
              build(job: 'test-suites/vendored-gems', parameters: buildParameters)
            }
          }
        }

        stage('Javascript') {
          steps {
            skipIfPreviouslySuccessful("javascript") {
              build(job: 'test-suites/JS', parameters: buildParameters)
            }
          }
        }

        stage('Contract Tests') {
          steps {
            skipIfPreviouslySuccessful("contract-tests") {
              build(job: 'test-suites/contract-tests', parameters: buildParameters)
            }
          }
        }

        stage('Selenium Chrome') {
          steps {
            skipIfPreviouslySuccessful("selenium-chrome") {
              build(
                job: 'test-suites/selenium-chrome',
                parameters: buildParameters + string(name: 'CI_NODE_TOTAL', value: env.SELENIUM_CI_NODE_TOTAL)
              )
            }
          }
        }

        stage('RSpec') {
          steps {
            skipIfPreviouslySuccessful("rspec") {
              build(
                job: 'test-suites/rspec',
                parameters: buildParameters + string(name: 'CI_NODE_TOTAL', value: env.RSPEC_CI_NODE_TOTAL)
              )
            }
          }
        }

        stage ('Flakey Spec Catcher') {
          when { expression { env.GERRIT_EVENT_TYPE != 'change-merged' } }
          steps {
            skipIfPreviouslySuccessful("flakey-spec-catcher") {
              build(
                job: 'test-suites/flakey-spec-catcher',
                parameters: buildParameters,
                propagate: false,
                wait: false
              )
            }
          }
        }

        // // keep this around in case there is changes to the subbuilds that need to happen
        // // and you have no other way to test it except by running a test build.
        // stage('Test Subbuild') {
        //   steps {
        //     skipIfPreviouslySuccessful("test-subbuild") {
        //       build(job: 'test-suites/test-subbuild', parameters: buildParameters)
        //     }
        //   }
        // }

        // // Don't run these on all patch sets until we have them ready to report results.
        // // Uncomment stage to run when developing.
        // stage('Xbrowser') {
        //   steps {
        //     skipIfPreviouslySuccessful("xbrowser") {
        //       // propagate set to false until we can get tests passing
        //       build(job: 'test-suites/xbrowser', propagate: false, parameters: buildParameters)
        //       )
        //     }
        //   }
        // }

      }
    }

    stage('Publish Image on Merge') {
      when {
        allOf {
          expression { isPatchsetPublishable() }
          expression { env.GERRIT_EVENT_TYPE == 'change-merged' }
        }
      }
      steps {
        timeout(time: 10) {
          script {
            // Retriggers won't have an image to tag/push, pull that
            // image if doesn't exist. If image is not found it will
            // return NULL
            if (!sh (script: 'docker images -q $PATCHSET_TAG')) {
              sh 'docker pull $PATCHSET_TAG'
            }
            sh 'docker tag $PUBLISHABLE_TAG $MERGE_TAG'
            // push *all* canvas-lms images (i.e. all canvas-lms prefixed tags)
            sh 'docker push $CANVAS_LMS_IMAGE'
          }
        }
      }
    }

    stage('Dependency Check') {
      when { expression { env.GERRIT_EVENT_TYPE == 'change-merged' } }
      steps {
        script {
          def reports = load 'build/new-jenkins/groovy/reports.groovy'
          reports.snykCheckDependencies("$PATCHSET_TAG", "/usr/src/app/")
        }
      }
    }

    stage('Mark Build as Successful') {
      steps {
        script {
          def successes = load 'build/new-jenkins/groovy/successes.groovy'
          successes.markBuildAsSuccessful()
        }
      }
    }
  }

  post {
    failure {
      script {
        if (isPatchsetPublishable() && env.GERRIT_EVENT_TYPE == 'change-merged') {
          slackSend(
            channel: '#canvas_builds',
            color: 'danger',
            message: "${env.JOB_NAME} failed on merge (<${env.BUILD_URL}|${env.BUILD_NUMBER}>)"
          )
        }
      }
    }

    cleanup {
      sh 'build/new-jenkins/docker-cleanup.sh --allow-failure'
    }
  }
}
