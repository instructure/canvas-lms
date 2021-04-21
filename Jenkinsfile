#!/usr/bin/env groovy

/*
 * Copyright (C) 2019 - present Instructure, Inc.MOD
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
def BLUE_OCEAN_TESTS_TAB = "display/redirect?page=tests"
def JS_BUILD_IMAGE_STAGE = "Javascript (Build Image)"

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

def dockerDevFiles = [
  '^docker-compose/',
  '^script/common/',
  '^script/canvas_update',
  '^docker-compose.yml',
  '^Dockerfile$',
  '^lib/tasks/',
  'Jenkinsfile.docker-smoke'
]

def jenkinsFiles = [
  'Jenkinsfile*',
  '^docker-compose.new-jenkins*.yml',
  'build/new-jenkins/*'
]

def getSummaryUrl() {
  return "${env.BUILD_URL}/build-summary-report"
}

def getDockerWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "/usr/src/app" : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}"
}

def getLocalWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "." : "gems/plugins/${env.GERRIT_PROJECT}"
}

def getRailsLoadAllLocales() {
  return configuration.isChangeMerged() ? 1 : (configuration.getBoolean('rails-load-all-locales', 'false') ? 1 : 0)
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
    libraryScript.execute 'bash/docker-cleanup.sh --allow-failure'
  }
}

def postFn(status) {
  try {
    def requestStartTime = System.currentTimeMillis()
    node('master') {
      def requestEndTime = System.currentTimeMillis()

      reportToSplunk('node_request_time', [
        'nodeName': 'master',
        'nodeLabel': 'master',
        'requestTime': requestEndTime - requestStartTime,
      ])

      buildSummaryReport.publishReport('Build Summary Report', status)

      if(status == 'SUCCESS' && configuration.isChangeMerged() && isPatchsetPublishable()) {
        dockerUtils.tagRemote(env.PATCHSET_TAG, env.MERGE_TAG)
        dockerUtils.tagRemote(env.CASSANDRA_IMAGE, env.CASSANDRA_MERGE_IMAGE)
        dockerUtils.tagRemote(env.DYNAMODB_IMAGE, env.DYNAMODB_MERGE_IMAGE)
        dockerUtils.tagRemote(env.POSTGRES_IMAGE, env.POSTGRES_MERGE_IMAGE)
      }
    }
  } finally {
    if(status == 'FAILURE') {
      maybeSlackSendFailure()
      maybeRetrigger()
    } else if(status == 'SUCCESS') {
      maybeSlackSendSuccess()
    }
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
    def extra = "Please investigate the cause of the failure, and respond to this message with your diagnosis. If you need help, don't hesitate to tag @ oncall and our on call will assist in looking at the build. Further details of our post-merge failure process can be found at this <${configuration.getFailureWiki()}|link>. Thanks!"

    slackSend(
      channel: getSlackChannel(),
      color: 'danger',
      message: "${authorSegment}. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\n$extra"
    )
  }
}

def maybeSlackSendSuccess() {
  if(configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'good',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> succeeded on re-trigger. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>"
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

def slackSendCacheBuild(block) {
  def buildStartTime = System.currentTimeMillis()

  block()

  def buildEndTime = System.currentTimeMillis()

  def buildLog = sh(script: 'cat tmp/docker-build.log', returnStdout: true).trim()
  def buildLogParts = buildLog.split('\n')
  def buildLogPartsLength = buildLogParts.size()

  // slackSend() has a ridiculously low limit of 2k, so we need to split longer logs
  // into parts.
  def i = 0
  def partitions = []
  def cur_partition = []
  def max_entries = 5

  while(i < buildLogPartsLength) {
    cur_partition.add(buildLogParts[i])

    if(cur_partition.size() >= max_entries) {
      partitions.add(cur_partition)

      cur_partition = []
    }

    i++
  }

  if(cur_partition.size() > 0) {
    partitions.add(cur_partition)
  }

  for(i = 0; i < partitions.size(); i++) {
    slackSend(
      channel: '#jenkins_cache_noisy',
      message: """<${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> on ${env.GERRIT_PROJECT}. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}> (${i} / ${partitions.size() - 1})
      Duration: ${buildEndTime - buildStartTime}ms
      Instance: ${env.NODE_NAME}

        ```${partitions[i].join('\n\n')}```
      """
    )
  }
}

// These functions are intentionally pinned to GERRIT_EVENT_TYPE == 'change-merged' to ensure that real post-merge
// builds always run correctly. We intentionally ignore overrides for version pins, docker image paths, etc when
// running real post-merge builds.
// =========
def getPluginVersion(plugin) {
  if(env.GERRIT_BRANCH.contains('stable/')) {
    return configuration.getString("pin-commit-$plugin", env.GERRIT_BRANCH)
  }
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? 'master' : configuration.getString("pin-commit-$plugin", "master")
}

def getSlackChannel() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

@groovy.transform.Field def CANVAS_BUILDS_REFSPEC_REGEX = /\[canvas\-builds\-refspec=(.+?)\]/

def getCanvasBuildsRefspec() {
  def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null

  if(env.GERRIT_EVENT_TYPE == 'change-merged' || !commitMessage || !(commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).find()) {
    return env.GERRIT_BRANCH.contains('stable/') ? env.GERRIT_BRANCH : 'master'
  }

  return (commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).findAll()[0][1]
}

@groovy.transform.Field def CANVAS_LMS_REFSPEC_REGEX = /\[canvas\-lms\-refspec=(.+?)\]/
def getCanvasLmsRefspec() {
  // If stable branch, first search commit message for canvas-lms-refspec. If not present use stable branch head on origin.
  if(env.GERRIT_BRANCH.contains('stable/')) {
    def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null
    if((commitMessage =~ CANVAS_LMS_REFSPEC_REGEX).find()) {
      return configuration.canvasLmsRefspec()
    }
    return "+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH"
  }
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? configuration.canvasLmsRefspecDefault() : configuration.canvasLmsRefspec()
}
// =========

def handleDockerBuildFailure(imagePrefix, e) {
  if(configuration.isChangeMerged() || configuration.getBoolean('upload-docker-image-failures', 'false')) {
    // DEBUG: In some cases, such as the the image build failing only on Jenkins, it can be useful to be able to
    // download the last successful layer to debug locally. If we ever start using buildkit for the relevant
    // images, then this approach will have to change as buildkit doesn't save the intermediate layers as images.

    sh(script: """
      docker tag \$(docker images | awk '{print \$3}' | awk 'NR==2') $imagePrefix-failed
      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $imagePrefix-failed
    """, label: 'upload failed image')
  }

  throw e
}

library "canvas-builds-library@${getCanvasBuildsRefspec()}"
loadLocalLibrary("local-lib", "build/new-jenkins/library")

configuration.setUseCommitMessageFlags(env.GERRIT_EVENT_TYPE != 'change-merged')
extendedStage.setAlwaysAllowStages([
    'Builder',
    'Setup',
    'Rebase',
    'Build Docker Image',
    'Run Migrations',
    'Parallel Run Tests',
    'Waiting',
])

pipeline {
  agent none
  options {
    ansiColor('xterm')
    timeout(time: 1, unit: 'HOURS')
    timestamps()
  }

  environment {
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
    BUILD_IMAGE = configuration.buildRegistryPath()
    POSTGRES = configuration.postgres()
    POSTGRES_CLIENT = configuration.postgresClient()
    SKIP_CACHE = configuration.skipCache()

    // e.g. postgres-12-ruby-2.6
    TAG_SUFFIX = imageTag.suffix()


    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PATCHSET_TAG = imageTag.patchset()

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PUBLISHABLE_TAG = imageTag.publishableTag()

    // e.g. canvas-lms:master when not on another branch
    MERGE_TAG = imageTag.mergeTag()

    // e.g. canvas-lms:01.123456.78; this is for consumers like Portal 2 who want to build a patchset
    EXTERNAL_TAG = imageTag.externalTag()

    ALPINE_MIRROR = configuration.alpineMirror()
    NODE = configuration.node()
    RUBY = configuration.ruby() // RUBY_VERSION is a reserved keyword for ruby installs
    RSPEC_PROCESSES = 4

    LINTER_DEBUG_IMAGE = "${configuration.buildRegistryPath("linter-debug")}:${imageTagVersion()}-$TAG_SUFFIX"

    CASSANDRA_PREFIX = configuration.buildRegistryPath('cassandra-migrations')
    DYNAMODB_PREFIX = configuration.buildRegistryPath('dynamodb-migrations')
    KARMA_BUILDER_PREFIX = configuration.buildRegistryPath("karma-builder")
    KARMA_RUNNER_PREFIX = configuration.buildRegistryPath("karma-runner")
    POSTGRES_PREFIX = configuration.buildRegistryPath('postgres-migrations')
    RUBY_RUNNER_PREFIX = configuration.buildRegistryPath("ruby-runner")
    YARN_RUNNER_PREFIX = configuration.buildRegistryPath("yarn-runner")
    WEBPACK_BUILDER_PREFIX = configuration.buildRegistryPath("webpack-builder")
    WEBPACK_CACHE_PREFIX = configuration.buildRegistryPath("webpack-cache")

    IMAGE_CACHE_BUILD_SCOPE = configuration.gerritChangeNumber()
    IMAGE_CACHE_MERGE_SCOPE = configuration.gerritBranchSanitized()
    IMAGE_CACHE_UNIQUE_SCOPE = "${imageTagVersion()}-$TAG_SUFFIX"

    CASSANDRA_IMAGE = "$CASSANDRA_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    DYNAMODB_IMAGE = "$DYNAMODB_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_IMAGE = "$POSTGRES_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    WEBPACK_BUILDER_IMAGE = "$WEBPACK_BUILDER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"

    CASSANDRA_MERGE_IMAGE = "$CASSANDRA_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-$RSPEC_PROCESSES"
    DYNAMODB_MERGE_IMAGE = "$DYNAMODB_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-$RSPEC_PROCESSES"
    KARMA_RUNNER_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_MERGE_IMAGE = "$POSTGRES_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-$RSPEC_PROCESSES"

    // This is primarily for the plugin build
    // for testing canvas-lms changes against plugin repo changes
    CANVAS_BUILDS_REFSPEC = getCanvasBuildsRefspec()
    CANVAS_LMS_REFSPEC = getCanvasLmsRefspec()
    DOCKER_WORKDIR = getDockerWorkDir()
    LOCAL_WORKDIR = getLocalWorkDir()
  }

  stages {
    stage('Environment') {
      steps {
        script {
          node('master') {
            if (configuration.skipCi()) {
              currentBuild.result = 'NOT_BUILT'
              gerrit.submitLintReview("-2", "Build not executed due to [skip-ci] flag")
              error "[skip-ci] flag enabled: skipping the build"
              return
            } else if(extendedStage.isAllowStagesFilterUsed()) {
              gerrit.submitLintReview("-2", "Complete build not executed due to [allow-stages] flag")
            } else {
              gerrit.submitLintReview("0")
            }
          }

          // Ensure that all build flags are compatible.
          if(configuration.getBoolean('change-merged') && configuration.isValueDefault('build-registry-path')) {
            error "Manually triggering the change-merged build path must be combined with a custom build-registry-path"
            return
          }

          maybeSlackSendRetrigger()

          def rootStages = [:]

          extendedStage.withOptions('Builder', rootStages, extendedStage.DISABLE_MEASURE_TIMINGS) {
            // Use a nospot instance for now to avoid really bad UX. Jenkins currently will
            // wait for the current steps to complete (even wait to spin up a node), causing
            // extremely long wait times for a restart. Investigation in DE-166 / DE-158.
            protectedNode('canvas-docker-nospot', { status -> cleanupFn(status) }, { status -> postFn(status) }) {
              buildSummaryReport.extendedStageAndReportIfFailure('Setup') {
                timeout(time: 2) {
                  echo "Cleaning Workspace From Previous Runs"
                  sh 'ls -A1 | xargs rm -rf'
                  sh 'find .'
                  cleanAndSetup()
                  def refspecToCheckout = env.GERRIT_PROJECT == "canvas-lms" ? env.GERRIT_REFSPEC : env.CANVAS_LMS_REFSPEC
                  checkoutRepo("canvas-lms", refspecToCheckout, 100)

                  if(env.GERRIT_PROJECT != "canvas-lms") {
                    dir(env.LOCAL_WORKDIR) {
                      checkoutRepo(GERRIT_PROJECT, env.GERRIT_REFSPEC, 2)
                    }

                    // Plugin builds using the dir step above will create this @tmp file, we need to remove it
                    // https://issues.jenkins.io/browse/JENKINS-52750
                    sh 'rm -vr gems/plugins/*@tmp'
                  }

                  buildParameters += string(name: 'CANVAS_BUILDS_REFSPEC', value: "${env.CANVAS_BUILDS_REFSPEC}")
                  buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
                  buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
                  buildParameters += string(name: 'RUBY', value: "${env.RUBY}")

                  // if (currentBuild.projectName.contains("rails-6")) {
                    // when updating this for future rails versions, change the value back to ${env.CANVAS_RAILSX_Y}
                    buildParameters += string(name: 'CANVAS_RAILS6_0', value: "1")
                  // }

                  // If modifying any of our Jenkinsfiles set JENKINSFILE_REFSPEC for sub-builds to use Jenkinsfiles in
                  // the gerrit rather than master.
                  if(env.GERRIT_PROJECT == 'canvas-lms' && git.changedFiles(jenkinsFiles, 'HEAD^') ) {
                      buildParameters += string(name: 'JENKINSFILE_REFSPEC', value: "${env.GERRIT_REFSPEC}")
                  }

                  if (env.GERRIT_PROJECT != "canvas-lms") {
                    // the plugin builds require the canvas lms refspec to be different. so only
                    // set this refspec if the main build is requesting it to be set.
                    // NOTE: this is only being set in main-from-plugin build. so main-canvas wont run this.
                    buildParameters += string(name: 'CANVAS_LMS_REFSPEC', value: env.CANVAS_LMS_REFSPEC)
                  }

                  gems = configuration.plugins()
                  echo "Plugin list: ${gems}"
                  def pluginsToPull = []
                  gems.each {
                    if (env.GERRIT_PROJECT != it) {
                      pluginsToPull.add([name: it, version: getPluginVersion(it), target: "gems/plugins/$it"])
                    }
                  }

                  pluginsToPull.add([name: 'qti_migration_tool', version: getPluginVersion('qti_migration_tool'), target: "vendor/qti_migration_tool"])

                  pullRepos(pluginsToPull)

                  libraryScript.load('bash/docker-tag-remote.sh', './build/new-jenkins/docker-tag-remote.sh')
                }
              }

              if(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms' && !configuration.skipRebase()) {
                buildSummaryReport.extendedStageAndReportIfFailure('Rebase') {
                  timeout(time: 2) {
                    rebaseHelper(GERRIT_BRANCH)

                    if(!env.JOB_NAME.endsWith('Jenkinsfile') && git.changedFiles(jenkinsFiles, 'origin/master')) {
                      error "Jenkinsfile has been updated. Please retrigger your patchset for the latest updates."
                    }
                  }
                }
              }

              if (configuration.isChangeMerged()) {
                buildSummaryReport.extendedStageAndReportIfFailure('Build Docker Image (Pre-Merge)') {
                  timeout(time: 20) {
                    credentials.withStarlordCredentials {
                      withEnv([
                        "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                        "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
                        "CACHE_SAVE_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                        "COMPILE_ADDITIONAL_ASSETS=0",
                        "JS_BUILD_NO_UGLIFY=1",
                        "RAILS_LOAD_ALL_LOCALES=0",
                        "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
                        "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
                        "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
                        "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
                      ]) {
                        slackSendCacheBuild {
                          try {
                            sh "build/new-jenkins/docker-build.sh"
                          } catch(e) {
                            handleDockerBuildFailure("$PATCHSET_TAG-pre-merge-failed", e)
                          }
                        }

                        // We need to attempt to upload all prefixes here in case instructure/ruby-passenger
                        // has changed between the post-merge build and this pre-merge build.
                        sh(script: """
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_PREFIX || true
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $YARN_RUNNER_PREFIX || true
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $RUBY_RUNNER_PREFIX || true
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX
                        """, label: 'upload cache images')
                      }
                    }
                  }
                }
              }

              buildSummaryReport.extendedStageAndReportIfFailure('Build Docker Image') {
                timeout(time: 20) {
                  credentials.withStarlordCredentials {
                    def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE

                    slackSendCacheBuild {
                      withEnv([
                        "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                        "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
                        "CACHE_SAVE_SCOPE=${cacheScope}",
                        "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
                        "COMPILE_ADDITIONAL_ASSETS=${configuration.isChangeMerged() ? 1 : 0}",
                        "JS_BUILD_NO_UGLIFY=${configuration.isChangeMerged() ? 0 : 1}",
                        "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
                        "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
                        "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
                        "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
                        "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
                      ]) {
                        try {
                          sh "build/new-jenkins/docker-build.sh $PATCHSET_TAG"
                        } catch(e) {
                          handleDockerBuildFailure(PATCHSET_TAG, e)
                        }
                      }
                    }

                    sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $PATCHSET_TAG"

                    if(configuration.isChangeMerged()) {
                      def GIT_REV = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                      sh "docker tag \$PATCHSET_TAG \$BUILD_IMAGE:${GIT_REV}"

                      sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push \$BUILD_IMAGE:${GIT_REV}"
                    }

                    sh(script: """
                      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_PREFIX || true
                      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $YARN_RUNNER_PREFIX || true
                      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $RUBY_RUNNER_PREFIX || true
                      ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX
                    """, label: 'upload cache images')

                    if (isPatchsetPublishable()) {
                      sh 'docker tag $PATCHSET_TAG $EXTERNAL_TAG'
                      sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $EXTERNAL_TAG'
                    }
                  }
                }
              }

              buildSummaryReport.extendedStageAndReportIfFailure('Run Migrations') {
                timeout(time: 10) {
                  credentials.withStarlordCredentials {
                    def cacheLoadScope = configuration.isChangeMerged() || configuration.getBoolean('skip-cache') ? '' : env.IMAGE_CACHE_MERGE_SCOPE
                    def cacheSaveScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : ''

                    withEnv([
                      "CACHE_LOAD_SCOPE=${cacheLoadScope}",
                      "CACHE_SAVE_SCOPE=${cacheSaveScope}",
                      "CACHE_UNIQUE_SCOPE=${env.IMAGE_CACHE_UNIQUE_SCOPE}",
                      "CASSANDRA_IMAGE_TAG=${imageTag.cassandra()}",
                      "CASSANDRA_PREFIX=${env.CASSANDRA_PREFIX}",
                      "COMPOSE_FILE=docker-compose.new-jenkins.yml",
                      "DYNAMODB_IMAGE_TAG=${imageTag.dynamodb()}",
                      "DYNAMODB_PREFIX=${env.DYNAMODB_PREFIX}",
                      "POSTGRES_IMAGE_TAG=${imageTag.postgres()}",
                      "POSTGRES_PREFIX=${env.POSTGRES_PREFIX}",
                      "POSTGRES_PASSWORD=sekret"
                    ]) {
                      sh """
                        # Due to https://issues.jenkins.io/browse/JENKINS-15146, we have to set it to empty string here
                        export CACHE_LOAD_SCOPE=\${CACHE_LOAD_SCOPE:-}
                        export CACHE_SAVE_SCOPE=\${CACHE_SAVE_SCOPE:-}
                        ./build/new-jenkins/run-migrations.sh
                        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $CASSANDRA_PREFIX || true
                        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $DYNAMODB_PREFIX || true
                        ./build/new-jenkins/docker-with-flakey-network-protection.sh push $POSTGRES_PREFIX || true
                      """
                    }

                    archiveArtifacts(artifacts: "migrate-*.log", allowEmptyArchive: true)
                    sh 'docker-compose down --remove-orphans'
                  }
                }
              }

              stage('Parallel Run Tests') {
                withEnv([
                    "CASSANDRA_IMAGE_TAG=${env.CASSANDRA_IMAGE}",
                    "DYNAMODB_IMAGE_TAG=${env.DYNAMODB_IMAGE}",
                    "POSTGRES_IMAGE_TAG=${env.POSTGRES_IMAGE}",
                ]) {
                  def stages = [:]

                  if (!configuration.isChangeMerged()) {
                    echo 'adding Linters'
                    buildSummaryReport.extendedStageAndReportIfFailure('Linters', stages) {
                      credentials.withStarlordCredentials {
                        credentials.withGerritCredentials {
                          withEnv([
                            "FORCE_FAILURE=${configuration.getBoolean('force-failure-linters', 'false')}",
                            "PLUGINS_LIST=${configuration.plugins().join(' ')}",
                            "SKIP_ESLINT=${configuration.getString('skip-eslint', 'false')}",
                            "UPLOAD_DEBUG_IMAGE=${configuration.getBoolean('upload-linter-debug-image', 'false')}",
                          ]) {
                            sh 'build/new-jenkins/linters/run-gergich.sh'
                          }
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
                  buildSummaryReport.extendedStageAndReportIfFailure('Consumer Smoke Test', stages) {
                    sh 'build/new-jenkins/consumer-smoke-test.sh'
                  }

                  echo 'adding Vendored Gems'
                  extendedStage('Vendored Gems', stages) {
                      buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/vendored-gems', buildParameters + [
                        string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                        string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                        string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                      ], true, "", "Vendored Gems")
                  }

                  buildSummaryReport.extendedStageAndReportIfFailure(JS_BUILD_IMAGE_STAGE, stages) {
                    credentials.withStarlordCredentials {
                      try {
                        def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE

                        withEnv([
                          "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                          "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
                          "CACHE_SAVE_SCOPE=${cacheScope}",
                          "KARMA_BUILDER_PREFIX=${env.KARMA_BUILDER_PREFIX}",
                          "PATCHSET_TAG=${env.PATCHSET_TAG}",
                          "RAILS_LOAD_ALL_LOCALES=${getRailsLoadAllLocales()}",
                          "WEBPACK_BUILDER_IMAGE=${env.WEBPACK_BUILDER_IMAGE}",
                        ]) {
                          sh "./build/new-jenkins/js/docker-build.sh $KARMA_RUNNER_IMAGE"
                        }

                        sh """
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $KARMA_RUNNER_IMAGE
                          ./build/new-jenkins/docker-with-flakey-network-protection.sh push $KARMA_BUILDER_PREFIX
                        """
                      } catch(e) {
                        handleDockerBuildFailure(KARMA_RUNNER_IMAGE, e)
                      }
                    }
                  }

                  echo 'adding Contract Tests'
                  extendedStage('Contract Tests', stages) {
                    buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/contract-tests', buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                    ], true, "", "Contract Tests")
                  }

                  if (sh(script: 'build/new-jenkins/check-for-migrations.sh', returnStatus: true) == 0) {
                    echo 'adding CDC Schema check'
                    extendedStage('CDC Schema Check', stages) {
                      buildSummaryReport.buildAndReportIfFailure('/Canvas/cdc-event-transformer-master', buildParameters + [
                        string(name: 'CANVAS_LMS_IMAGE_PATH', value: "${env.PATCHSET_TAG}"),
                      ], true, "", "CDC Schema Check")
                    }
                  }
                  else {
                    echo 'no migrations added, skipping CDC Schema check'
                  }

                  if (
                    !configuration.isChangeMerged() &&
                    (
                      dir(env.LOCAL_WORKDIR){ (sh(script: '${WORKSPACE}/build/new-jenkins/spec-changes.sh', returnStatus: true) == 0) } ||
                      configuration.forceFailureFSC() == '1'
                    )
                  ) {
                    echo 'adding Flakey Spec Catcher'
                    extendedStage('Flakey Spec Catcher', stages) {
                      buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/flakey-spec-catcher', buildParameters + [
                        string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                        string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                        string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                      ], configuration.fscPropagate(), "", "Flakey Spec Catcher")
                    }
                  }

                  // Flakey spec catcher using the dir step above will create this @tmp file, we need to remove it
                  // https://issues.jenkins.io/browse/JENKINS-52750
                  if(!configuration.isChangeMerged() && env.GERRIT_PROJECT != "canvas-lms") {
                    sh "rm -vrf $LOCAL_WORKDIR@tmp"
                  }

                  if(env.GERRIT_PROJECT == 'canvas-lms' && git.changedFiles(dockerDevFiles, 'HEAD^')) {
                    echo 'adding Local Docker Dev Build'
                    extendedStage('Local Docker Dev Build', stages) {
                      buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/local-docker-dev-smoke', buildParameters, true, "", "Local Docker Dev Build")
                    }
                  }

                  if(configuration.isChangeMerged()) {
                    buildSummaryReport.extendedStageAndReportIfFailure('Dependency Check', stages) {
                      catchError (buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        try {
                          snyk("canvas-lms:ruby", "Gemfile.lock", "$PATCHSET_TAG")
                        }
                        catch (err) {
                          if (err.toString().contains('Gemfile.lock does not exist')) {
                            snyk("canvas-lms:ruby", "Gemfile.lock.next", "$PATCHSET_TAG")
                          } else {
                            throw err
                          }
                        }
                      }
                    }
                  }

                  distribution.stashBuildScripts()

                  distribution.addRSpecSuites(stages)
                  distribution.addSeleniumSuites(stages)

                  parallel(stages)
                }
              }
            }
          }

          extendedStage.withOptions("Javascript (Waiting for Dependencies)", rootStages, extendedStage.dependsOn(JS_BUILD_IMAGE_STAGE, 'Builder')) {
            def nestedStages = [:]

            echo 'adding Javascript (Jest)'
            extendedStage.withOptions('Javascript (Jest)', nestedStages, extendedStage.dependsOn(JS_BUILD_IMAGE_STAGE)) {
              buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/JS', buildParameters + [
                string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                string(name: 'TEST_SUITE', value: "jest"),
              ], true, BLUE_OCEAN_TESTS_TAB, "Javascript (Jest)")
            }

            echo 'adding Javascript (Coffeescript)'
            extendedStage.withOptions('Javascript (Coffeescript)', nestedStages, extendedStage.dependsOn(JS_BUILD_IMAGE_STAGE)) {
              buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/JS', buildParameters + [
                string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                string(name: 'TEST_SUITE', value: "coffee"),
              ], true, BLUE_OCEAN_TESTS_TAB, "Javascript (Coffeescript)")
            }

            echo 'adding Javascript (Karma)'
            extendedStage.withOptions('Javascript (Karma)', nestedStages, extendedStage.dependsOn(JS_BUILD_IMAGE_STAGE)) {
              buildSummaryReport.buildAndReportIfFailure('/Canvas/test-suites/JS', buildParameters + [
                string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                string(name: 'TEST_SUITE', value: "karma"),
              ], true, BLUE_OCEAN_TESTS_TAB, "Javascript (Karma)")
            }

            parallel(nestedStages)
          }

          parallel(rootStages)
        }//script
      }//steps
    }//environment
  }//stages
}//pipeline
