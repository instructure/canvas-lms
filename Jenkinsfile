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
import org.jenkinsci.plugins.workflow.support.steps.build.DownstreamFailureCause
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

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

library "canvas-builds-library"

def getDockerWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "/usr/src/app" : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}"
}

def getLocalWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "." : "gems/plugins/${env.GERRIT_PROJECT}"
}

def skipIfPreviouslySuccessful(name, block) {
  if (env.CANVAS_LMS_REFSPEC && !env.CANVAS_LMS_REFSPEC.contains('master')) {
    name+="${env.CANVAS_LMS_REFSPEC}"
  }
  def successes = load('build/new-jenkins/groovy/successes.groovy')
  successes.skipIfPreviouslySuccessful(name, true, block)
}

def wrapBuildExecution(jobName, parameters, propagate, urlExtra) {
  try {
    build(job: jobName, parameters: parameters, propagate: propagate)
  }
  catch(FlowInterruptedException ex) {
    // if its this type, then that means its a build failure.
    // other reasons can be user cancelling or jenkins aborting, etc...
    def failure = ex.causes.find { it instanceof DownstreamFailureCause }
    if (failure != null) {
      def downstream = failure.getDownstreamBuild()
      def url = downstream.getAbsoluteUrl() + urlExtra
      load('build/new-jenkins/groovy/reports.groovy').appendFailMessageReport(jobName, url)
    }
    throw ex
  }
}

// if the build never starts or gets into a node block, then we
// can never load a file. and a very noisy/confusing error is thrown.
def ignoreBuildNeverStartedError(block) {
  try {
    block()
  }
  catch (org.jenkinsci.plugins.workflow.steps.MissingContextVariableException ex) {
    if (!ex.message.startsWith('Required context class hudson.FilePath is missing')) {
      throw ex
    }
    else {
      echo "ignored MissingContextVariableException: \n${ex.message}"
    }
    // we can ignore this very noisy error
  }
}

// return false if the current patchset tag doesn't match the
// mainline publishable tag. i.e. ignore pg-9.5 builds
def isPatchsetPublishable() {
  env.PATCHSET_TAG == env.PUBLISHABLE_TAG
}

def isPatchsetRetriggered() {
  if(env.IS_AUTOMATIC_RETRIGGER == '1') {
    return true
  }

  def userCause = currentBuild.getBuildCauses('com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.GerritUserCause')

  return userCause && userCause[0].shortDescription.contains('Retriggered')
}

def cleanupFn(status) {
  ignoreBuildNeverStartedError {
    try {
      def rspec = load 'build/new-jenkins/groovy/rspec.groovy'
      rspec.uploadJunitReports()
      rspec.uploadSeleniumFailures()
      rspec.uploadRSpecFailures()
      load('build/new-jenkins/groovy/reports.groovy').sendFailureMessageIfPresent()
    } finally {
      execute 'bash/docker-cleanup.sh --allow-failure'
    }
  }
}

def postFn(status) {
  if(status == 'FAILURE') {
    maybeSlackSendFailure()
    maybeRetrigger()
  } else if(status == 'SUCCESS') {
    maybeSlackSendSuccess()
  }
}

def shouldPatchsetRetrigger() {
  // NOTE: The IS_AUTOMATIC_RETRIGGER check is here to ensure that the parameter is properly defined for the triggering job.
  // If it isn't, we have the risk of triggering this job over and over in an infinite loop.
  return env.IS_AUTOMATIC_RETRIGGER == '0' && (
    env.GERRIT_EVENT_TYPE == 'change-merged' ||
    configuration.getBoolean('change-merged') && configuration.getBoolean('enable-automatic-retrigger', '0')
  )
}

def maybeRetrigger() {
  if(shouldPatchsetRetrigger() && !isPatchsetRetriggered()) {
    def retriggerParams = currentBuild.rawBuild.getAction(ParametersAction).getParameters()

    retriggerParams = retriggerParams.findAll { record ->
      record.name != 'IS_AUTOMATIC_RETRIGGER'
    }

    retriggerParams << new StringParameterValue('IS_AUTOMATIC_RETRIGGER', "1")

    build(job: env.JOB_NAME, parameters: retriggerParams, propagate: false, wait: false)
  }
}

def maybeSlackSendFailure() {
  if(configuration.isChangeMerged()) {
    def branchSegment = env.GERRIT_BRANCH ? "[$env.GERRIT_BRANCH]" : ''
    def authorSlackId = env.GERRIT_EVENT_ACCOUNT_EMAIL ? slackUserIdFromEmail(email: env.GERRIT_EVENT_ACCOUNT_EMAIL, botUser: true, tokenCredentialId: 'slack-user-id-lookup') : ''
    def authorSlackMsg = authorSlackId ? "<@$authorSlackId>" : env.GERRIT_EVENT_ACCOUNT_NAME
    def authorSegment = "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${authorSlackMsg} failed against ${branchSegment}"
    def extra = "Please investigate the cause of the failure, and respond to this message with your diagnosis. If you need help, please don't hesitate to tag @ oncall and our on call will assist in looking at the build. For further details of our post-merge failure process, please see this <${configuration.getFailureWiki()}|link>. Thanks!"

    slackSend(
      channel: getSlackChannel(),
      color: 'danger',
      message: "${authorSegment}. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>\n\n$extra"
    )
  }
}

def maybeSlackSendSuccess() {
  if(configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'good',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> succeeded on re-trigger. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

def maybeSlackSendRetrigger() {
  if(configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'warning',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${env.GERRIT_EVENT_ACCOUNT_EMAIL} has been re-triggered. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

// These functions are intentionally pinned to GERRIT_EVENT_TYPE == 'change-merged' to ensure that real post-merge
// builds always run correctly. We intentionally ignore overrides for version pins, docker image paths, etc when
// running real post-merge builds.
// =========
def getBuildImage() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? configuration.buildRegistryPathDefault() : configuration.buildRegistryPath()
}

def getPatchsetTag() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? imageTag.patchsetDefault() : imageTag.patchset()
}

def getPluginVersion(plugin) {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? 'master' : configuration.getString("pin-commit-$plugin", "master")
}

def getSlackChannel() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

// =========

pipeline {
  agent none
  options {
    ansiColor('xterm')
    timestamps()
  }

  environment {
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    NAME = imageTagVersion()
    BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
    BUILD_IMAGE = getBuildImage()
    POSTGRES = configuration.postgres()
    POSTGRES_CLIENT = configuration.postgresClient()
    SKIP_CACHE = configuration.skipCache()

    // e.g. postgres-12-ruby-2.6
    TAG_SUFFIX = imageTag.suffix()

    // this is found in the PUBLISHABLE_TAG_SUFFIX config file on jenkins
    PUBLISHABLE_TAG_SUFFIX = configuration.publishableTagSuffix()

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PATCHSET_TAG = getPatchsetTag()

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PUBLISHABLE_TAG = "$BUILD_IMAGE:$NAME-$PUBLISHABLE_TAG_SUFFIX"

    // e.g. canvas-lms:master when not on another branch
    MERGE_TAG = "$BUILD_IMAGE:$GERRIT_BRANCH"

    // e.g. canvas-lms:01.123456.78; this is for consumers like Portal 2 who want to build a patchset
    EXTERNAL_TAG = "$BUILD_IMAGE:$NAME"

    ALPINE_MIRROR = configuration.alpineMirror()
    NODE = configuration.node()
    RUBY = configuration.ruby() // RUBY_VERSION is a reserved keyword for ruby installs

    DEPENDENCIES_IMAGE = "$BUILD_IMAGE-dependencies"
    DEPENDENCIES_MERGE_IMAGE = "$DEPENDENCIES_IMAGE:$GERRIT_BRANCH"
    DEPENDENCIES_PATCHSET_IMAGE = "$DEPENDENCIES_IMAGE:$NAME-$TAG_SUFFIX"

    CASSANDRA_IMAGE_TAG=imageTag.cassandra()
    DYNAMODB_IMAGE_TAG=imageTag.dynamodb()
    POSTGRES_IMAGE_TAG=imageTag.postgres()
    // This is primarily for the plugin build
    // for testing canvas-lms changes against plugin repo changes
    CANVAS_LMS_REFSPEC=configuration.canvasLmsRefspec()
    DOCKER_WORKDIR = getDockerWorkDir()
    LOCAL_WORKDIR = getLocalWorkDir()
  }

  stages {
    stage('Environment') {
      steps {
        script {
          // Ensure that all build flags are compatible.

          if(configuration.getBoolean('change-merged') && configuration.isValueDefault('build-registry-path')) {
            error "Manually triggering the change-merged build path must be combined with a custom build-registry-path"
            return
          }

          maybeSlackSendRetrigger()

          // Use a nospot instance for now to avoid really bad UX. Jenkins currently will
          // wait for the current steps to complete (even wait to spin up a node), causing
          // extremely long wait times for a restart. Investigation in DE-166 / DE-158.
          protectedNode('canvas-docker-nospot', { status -> cleanupFn(status) }, { status -> postFn(status) }) {
            stage('Setup') {
              timeout(time: 5) {
                cleanAndSetup()
                // If using custom CANVAS_LMS_REFSPEC do custom checkout to get correct code
                if (env.CANVAS_LMS_REFSPEC && !env.CANVAS_LMS_REFSPEC.contains('master')) {
                  checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'FETCH_HEAD']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                      credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35',
                      name: 'origin',
                      refspec: "$env.CANVAS_LMS_REFSPEC",
                      url: "ssh://gerrit.instructure.com:29418/canvas-lms.git"
                    ]]
                  ])
                } else {
                  checkout scm
                }

                buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
                buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
                buildParameters += string(name: 'RUBY', value: "${env.RUBY}")
                if (currentBuild.projectName.contains("main-from-plugin")) {
                  // the plugin builds require the canvas lms refspec to be different. so only
                  // set this refspec if the main build is requesting it to be set.
                  // NOTE: this is only being set in main-from-plugin build. so main-canvas wont run this.
                  buildParameters += string(name: 'CANVAS_LMS_REFSPEC', value: env.CANVAS_LMS_REFSPEC)
                }

                pullGerritRepo('gerrit_builder', 'master', '.')
                gems = readFile('gerrit_builder/canvas-lms/config/plugins_list').split()
                echo "Plugin list: ${gems}"
                // fetch plugins
                gems.each { gem ->
                  if (env.GERRIT_PROJECT == gem) {
                    /* this is the commit we're testing */
                    dir(env.LOCAL_WORKDIR) {
                      checkout([
                        $class: 'GitSCM',
                        branches: [[name: 'FETCH_HEAD']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [],
                        submoduleCfg: [],
                        userRemoteConfigs: [[
                          credentialsId: '44aa91d6-ab24-498a-b2b4-911bcb17cc35',
                          name: 'origin',
                          refspec: "$env.GERRIT_REFSPEC",
                          url: "ssh://$GERRIT_URL/${GERRIT_PROJECT}.git"
                        ]]
                      ])
                    }
                  } else {
                    pullGerritRepo(gem, getPluginVersion(gem), 'gems/plugins')
                  }
                }
                pullGerritRepo("qti_migration_tool", getPluginVersion('qti_migration_tool'), "vendor")

                // Plugin builds using the checkout above will create this @tmp file, we need to remove it
                sh(script: 'rm -vr gems/plugins/*@tmp', returnStatus: true)
                sh 'mv -v gerrit_builder/canvas-lms/config/* config/'
                sh 'rm -v config/cache_store.yml'
                sh 'rm -vr gerrit_builder'
                sh 'rm -v config/database.yml'
                sh 'rm -v config/security.yml'
                sh 'rm -v config/selenium.yml'
                sh 'rm -v config/file_store.yml'
                sh 'cp -v docker-compose/config/selenium.yml config/'
                sh 'cp -vR docker-compose/config/new-jenkins/* config/'
                sh 'cp -v config/delayed_jobs.yml.example config/delayed_jobs.yml'
                sh 'cp -v config/domain.yml.example config/domain.yml'
                sh 'cp -v config/external_migration.yml.example config/external_migration.yml'
                sh 'cp -v config/outgoing_mail.yml.example config/outgoing_mail.yml'
              }
            }

            if(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms' && !configuration.skipRebase()) {
              stage('Rebase') {
                timeout(time: 2) {
                  credentials.withGerritCredentials({ ->
                    sh '''#!/bin/bash
                      set -o errexit -o errtrace -o nounset -o pipefail -o xtrace

                      GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                        git fetch origin $GERRIT_BRANCH:origin/$GERRIT_BRANCH

                      git config user.name "$GERRIT_EVENT_ACCOUNT_NAME"
                      git config user.email "$GERRIT_EVENT_ACCOUNT_EMAIL"

                      # this helps current build issues where cleanup is needed before proceeding.
                      # however the later git rebase --abort should be enough but sometimes isn't.
                      if [ -d .git/rebase-merge ]; then
                        echo "A previous build's rebase failed and the build exited without cleaning up. Aborting the previous rebase now..."
                        git rebase --abort
                        GIT_SSH_COMMAND='ssh -i \"$SSH_KEY_PATH\" -l \"$SSH_USERNAME\"' \
                          git fetch origin $GERRIT_REFSPEC && git checkout FETCH_HEAD
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

            stage('Build Docker Image') {
              timeout(time: 30) {
                skipIfPreviouslySuccessful('docker-build-and-push') {
                  if (!configuration.isChangeMerged() && configuration.skipDockerBuild()) {
                    sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $MERGE_TAG'
                    sh 'docker tag $MERGE_TAG $PATCHSET_TAG'
                  } else {
                    withEnv([
                      "JS_BUILD_NO_UGLIFY=${configuration.isChangeMerged() ? 0 : 1}"
                    ]) {
                      sh 'build/new-jenkins/docker-build.sh'
                    }
                    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $DEPENDENCIES_PATCHSET_IMAGE"
                  }
                  sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $PATCHSET_TAG"
                  if (isPatchsetPublishable()) {
                    sh 'docker tag $PATCHSET_TAG $EXTERNAL_TAG'
                    sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $EXTERNAL_TAG'
                  }
                }
              }
            }

            stage('Parallel Run Tests') {
              def stages = [:]
              if (!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms') {
                echo 'adding Linters'
                stages['Linters'] = {
                  skipIfPreviouslySuccessful("linters") {
                    credentials.withGerritCredentials {
                      sh 'build/new-jenkins/linters/run-gergich.sh'
                    }
                    if (env.MASTER_BOUNCER_RUN == '1' && !configuration.isChangeMerged()) {
                      credentials.withMasterBouncerCredentials {
                        sh 'build/new-jenkins/linters/run-master-bouncer.sh'
                      }
                    }
                  }
                }
              }

              echo 'adding Consumer Smoke Test'
              stages['Consumer Smoke Test'] = {
                skipIfPreviouslySuccessful("consumer-smoke-test") {
                  sh 'build/new-jenkins/consumer-smoke-test.sh'
                }
              }

              echo 'adding Vendored Gems'
              stages['Vendored Gems'] = {
                skipIfPreviouslySuccessful("vendored-gems") {
                  wrapBuildExecution('/Canvas/test-suites/vendored-gems', buildParameters + [
                    string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                    string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                    string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                  ], true, "")
                }
              }

              echo 'adding Javascript (Jest)'
              stages['Javascript (Jest)'] = {
                skipIfPreviouslySuccessful("javascript_jest") {
                  wrapBuildExecution('/Canvas/test-suites/JS', buildParameters + [
                    string(name: 'TEST_SUITE', value: "jest"),
                  ], true, "testReport")
                }
              }

              echo 'adding Javascript (Karma)'
              stages['Javascript (Karma)'] = {
                skipIfPreviouslySuccessful("javascript_karma") {
                  wrapBuildExecution('/Canvas/test-suites/JS', buildParameters + [
                    string(name: 'TEST_SUITE', value: "karma"),
                  ], true, "testReport")
                }
              }

              echo 'adding Contract Tests'
              stages['Contract Tests'] = {
                skipIfPreviouslySuccessful("contract-tests") {
                  wrapBuildExecution('/Canvas/test-suites/contract-tests', buildParameters + [
                    string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                    string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                    string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                  ], true, "")
                }
              }

              if (sh(script: 'build/new-jenkins/check-for-migrations.sh', returnStatus: true) == 0) {
                echo 'adding CDC Schema check'
                stages['CDC Schema Check'] = {
                  build job: '../Canvas/cdc-event-transformer-master', parameters: [
                    string(name: 'CANVAS_LMS_IMAGE_TAG', value: "${env.NAME}-${env.TAG_SUFFIX}")
                  ]
                }
              }
              else {
                echo 'no migrations added, skipping CDC Schema check'
              }

              if (!configuration.isChangeMerged() && dir(env.LOCAL_WORKDIR){ (sh(script: '${WORKSPACE}/build/new-jenkins/spec-changes.sh', returnStatus: true) == 0) }) {
                echo 'adding Flakey Spec Catcher'
                stages['Flakey Spec Catcher'] = {
                  skipIfPreviouslySuccessful("flakey-spec-catcher") {
                    def propagate = configuration.fscPropagate()
                    echo "fsc propagation: $propagate"
                    wrapBuildExecution('/Canvas/test-suites/flakey-spec-catcher', buildParameters  + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                    ], propagate, "")
                  }
                }
              }

              if((sh(script: 'build/new-jenkins/docker-dev-changes.sh', returnStatus: true) == 0)) {
                echo 'adding Local Docker Dev Build'
                stages['Local Docker Dev Build'] = {
                  skipIfPreviouslySuccessful("local-docker-dev-smoke") {
                    wrapBuildExecution('/Canvas/test-suites/local-docker-dev-smoke', buildParameters, true, "")
                  }
                }
              }


              // // keep this around in case there is changes to the subbuilds that need to happen
              // // and you have no other way to test it except by running a test build.
              // stages['Test Subbuild'] = {
              //   skipIfPreviouslySuccessful("test-subbuild") {
              //     build(job: '/Canvas/proofs-of-concept/test-subbuild', parameters: buildParameters)
              //   }
              // }

              // // Don't run these on all patch sets until we have them ready to report results.
              // // Uncomment stage to run when developing.
              // stages['Xbrowser'] = {
              //   skipIfPreviouslySuccessful("xbrowser") {
              //     build(job: '/Canvas/proofs-of-concept/xbrowser', propagate: false, parameters: buildParameters)
              //   }
              // }

              def distribution = load 'build/new-jenkins/groovy/distribution.groovy'
              distribution.stashBuildScripts()

              distribution.addRSpecSuites(stages)
              distribution.addSeleniumSuites(stages)

              parallel(stages)
            }

            if(configuration.isChangeMerged() && isPatchsetPublishable()) {
              stage('Publish Image on Merge') {
                timeout(time: 10) {
                  // Retriggers won't have an image to tag/push, pull that
                  // image if doesn't exist. If image is not found it will
                  // return NULL
                  if (!sh (script: 'docker images -q $DEPENDENCIES_PATCHSET_IMAGE')) {
                    sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $DEPENDENCIES_PATCHSET_IMAGE'
                  }

                  if (!sh (script: 'docker images -q $PATCHSET_TAG')) {
                    sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $PATCHSET_TAG'
                  }

                  // publish canvas-lms:$GERRIT_BRANCH (i.e. canvas-lms:master)
                  sh 'docker tag $PUBLISHABLE_TAG $MERGE_TAG'
                  sh 'docker tag $DEPENDENCIES_PATCHSET_IMAGE $DEPENDENCIES_MERGE_IMAGE'

                  def GIT_REV = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                  sh "docker tag \$PUBLISHABLE_TAG \$BUILD_IMAGE:${GIT_REV}"
                  sh "docker tag \$DEPENDENCIES_PATCHSET_IMAGE \$DEPENDENCIES_IMAGE:${GIT_REV}"

                  // push *all* canvas-lms images (i.e. all canvas-lms prefixed tags)
                  sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $BUILD_IMAGE'
                  sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $DEPENDENCIES_IMAGE'
                }
              }
            }

            if(configuration.isChangeMerged()) {
              stage('Dependency Check') {
                def reports = load 'build/new-jenkins/groovy/reports.groovy'
                reports.snykCheckDependencies("$PATCHSET_TAG", "/usr/src/app/")
              }
            }

            stage('Mark Build as Successful') {
              def successes = load 'build/new-jenkins/groovy/successes.groovy'
              successes.markBuildAsSuccessful()
            }
          }//protectedNode
        }//script
      }//steps
    }//environment
  }//stages
}//pipline
