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

final static JS_BUILD_IMAGE_STAGE = 'Javascript (Build Image)'
final static LINTERS_BUILD_IMAGE_STAGE = 'Linters (Build Image)'
final static RUN_MIGRATIONS_STAGE = 'Run Migrations'

def buildParameters = [
  string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
  string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
  string(name: 'GERRIT_PROJECT', value: "${env.GERRIT_PROJECT}"),
  string(name: 'GERRIT_BRANCH', value: "${env.GERRIT_BRANCH}"),
  string(name: 'GERRIT_CHANGE_NUMBER', value: "${env.GERRIT_CHANGE_NUMBER}"),
  string(name: 'GERRIT_CHANGE_SUBJECT', value: "${env.GERRIT_CHANGE_SUBJECT}"),
  string(name: 'GERRIT_PATCHSET_NUMBER', value: "${env.GERRIT_PATCHSET_NUMBER}"),
  string(name: 'GERRIT_PATCHSET_REVISION', value: "${env.GERRIT_PATCHSET_REVISION}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_NAME', value: "${env.GERRIT_EVENT_ACCOUNT_NAME}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_EMAIL', value: "${env.GERRIT_EVENT_ACCOUNT_EMAIL}"),
  string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', value: "${env.GERRIT_CHANGE_COMMIT_MESSAGE}"),
  string(name: 'GERRIT_HOST', value: "${env.GERRIT_HOST}"),
  string(name: 'GERGICH_PUBLISH', value: "${env.GERGICH_PUBLISH}"),
  string(name: 'MASTER_BOUNCER_RUN', value: "${env.MASTER_BOUNCER_RUN}"),
  string(name: 'CRYSTALBALL_MAP_S3_VERSION', value: "${env.CRYSTALBALL_MAP_S3_VERSION}")
]

def getSummaryUrl() {
  return "${env.BUILD_URL}/build-summary-report"
}

def getDockerWorkDir() {
  if (env.GERRIT_PROJECT == 'qti_migration_tool') {
    return "/usr/src/app/vendor/${env.GERRIT_PROJECT}"
  }

  return env.GERRIT_PROJECT == 'canvas-lms' ? '/usr/src/app' : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}"
}

def getLocalWorkDir() {
  if (env.GERRIT_PROJECT == 'qti_migration_tool') {
    return "vendor/${env.GERRIT_PROJECT}"
  }

  return env.GERRIT_PROJECT == 'canvas-lms' ? '.' : "gems/plugins/${env.GERRIT_PROJECT}"
}

// return false if the current patchset tag doesn't match the
// mainline publishable tag. i.e. ignore pg-9.5 builds
def isPatchsetPublishable() {
  env.PATCHSET_TAG == env.PUBLISHABLE_TAG
}

def isPatchsetRetriggered() {
  if (env.IS_AUTOMATIC_RETRIGGER == '1') {
    return true
  }

  def userCause = currentBuild.getBuildCauses('com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.GerritUserCause')

  return userCause && userCause[0].shortDescription.contains('Retriggered')
}

def isStartedByUser() {
  return currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
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

      if (isPatchsetPublishable()) {
        dockerUtils.tagRemote(env.PATCHSET_TAG, env.EXTERNAL_TAG)
      }

      if (status == 'SUCCESS' && configuration.isChangeMerged() && isPatchsetPublishable()) {
        dockerUtils.tagRemote(env.PATCHSET_TAG, env.MERGE_TAG)
        dockerUtils.tagRemote(env.CASSANDRA_IMAGE_TAG, env.CASSANDRA_MERGE_IMAGE)
        dockerUtils.tagRemote(env.DYNAMODB_IMAGE_TAG, env.DYNAMODB_MERGE_IMAGE)
        dockerUtils.tagRemote(env.POSTGRES_IMAGE_TAG, env.POSTGRES_MERGE_IMAGE)
        dockerUtils.tagRemote(env.KARMA_RUNNER_IMAGE, env.KARMA_MERGE_IMAGE)
      }

      if (isStartedByUser()) {
        gerrit.submitVerified((status == 'SUCCESS' ? '+1' : '-1'), "${env.BUILD_URL}/build-summary-report/")
      }
    }

    build(job: "/Canvas/helpers/junit-uploader", parameters: [
      string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
      string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
      string(name: 'SOURCE', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
    ], propagate: false, wait: false)
  } finally {
    if (status == 'SUCCESS') {
      maybeSlackSendSuccess()
    } else {
      maybeSlackSendFailure()
      maybeRetrigger()
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
  if (shouldPatchsetRetrigger() && !isPatchsetRetriggered()) {
    def retriggerParams = currentBuild.rawBuild.getAction(ParametersAction).getParameters()

    retriggerParams = retriggerParams.findAll { record ->
      record.name != 'IS_AUTOMATIC_RETRIGGER'
    }

    retriggerParams << new StringParameterValue('IS_AUTOMATIC_RETRIGGER', '1')

    build(job: env.JOB_NAME, parameters: retriggerParams, propagate: false, wait: false)
  }
}

def maybeSlackSendFailure() {
  if (configuration.isChangeMerged()) {
    def branchSegment = env.GERRIT_BRANCH ? "[$env.GERRIT_BRANCH]" : ''
    def authorSlackId = env.GERRIT_EVENT_ACCOUNT_EMAIL ? slackUserIdFromEmail(email: env.GERRIT_EVENT_ACCOUNT_EMAIL, botUser: true, tokenCredentialId: 'slack-user-id-lookup') : ''
    def authorSlackMsg = authorSlackId ? "<@$authorSlackId>" : env.GERRIT_EVENT_ACCOUNT_NAME
    def authorSegment = "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${authorSlackMsg} failed against ${branchSegment}"
    def extra = 'Oh no! Your build failed the post-merge checks. If you have a test failure not related to your build, please reach out to the owning team and ask them to skip or fix the failed test. Spec flakiness can be investigated <https://inst.splunkcloud.com/en-US/app/search/canvas_spec_tracker|here>. Otherwise, tag our @ oncall for help in diagnosing the build issue if it is unclear.'

    slackSend(
      channel: getSlackChannel(),
      color: 'danger',
      message: "${authorSegment}. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\n$extra"
    )
  }

  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'danger',
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> failed. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>. (${currentBuild.durationString})"
  )
}

def maybeSlackSendSuccess() {
  if (configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'good',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> succeeded on re-trigger. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>"
    )
  }

  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'good',
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> succeeded. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>. (${currentBuild.durationString})"
  )
}

def maybeSlackSendRetrigger() {
  if (configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'warning',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${env.GERRIT_EVENT_ACCOUNT_EMAIL} has been re-triggered. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

@groovy.transform.Field final static GERRIT_CHANGE_ID_REGEX = /Change\-Id: (.*)/

def getChangeId() {
  if (env.GERRIT_CHANGE_ID) {
    return env.GERRIT_CHANGE_ID
  }
  def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null
  if (!commitMessage) {
    error 'GERRIT_CHANGE_COMMIT_MESSAGE not found! You must provide a commit message!'
  }
  return (commitMessage =~ GERRIT_CHANGE_ID_REGEX).findAll()[0][1]
}

// These functions are intentionally pinned to GERRIT_EVENT_TYPE == 'change-merged' to ensure that real post-merge
// builds always run correctly. We intentionally ignore overrides for version pins, docker image paths, etc when
// running real post-merge builds.
// =========

def getSlackChannel() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

@groovy.transform.Field final static CANVAS_BUILDS_REFSPEC_REGEX = /\[canvas\-builds\-refspec=(.+?)\]/

def getCanvasBuildsRefspec() {
  def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null

  if (env.GERRIT_EVENT_TYPE == 'change-merged' || !commitMessage || !(commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).find()) {
    return env.GERRIT_BRANCH.contains('stable/') ? env.GERRIT_BRANCH : 'master'
  }

  return (commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).findAll()[0][1]
}

@groovy.transform.Field final static CANVAS_LMS_REFSPEC_REGEX = /\[canvas\-lms\-refspec=(.+?)\]/
def getCanvasLmsRefspec() {
  // If stable branch, first search commit message for canvas-lms-refspec. If not present use stable branch head on origin.
  if (env.GERRIT_BRANCH.contains('stable/')) {
    def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null

    if ((commitMessage =~ CANVAS_LMS_REFSPEC_REGEX).find()) {
      return configuration.canvasLmsRefspec()
    }

    return "+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH"
  }

  return env.GERRIT_EVENT_TYPE == 'change-merged' ? configuration.canvasLmsRefspecDefault() : configuration.canvasLmsRefspec()
}
// =========

library "canvas-builds-library@${getCanvasBuildsRefspec()}"
loadLocalLibrary('local-lib', 'build/new-jenkins/library')

configuration.setUseCommitMessageFlags(env.GERRIT_EVENT_TYPE != 'change-merged')
protectedNode.setReportUnhandledExceptions(!env.JOB_NAME.endsWith('Jenkinsfile'))

pipeline {
  agent none
  options {
    ansiColor('xterm')
    timeout(time: 8, unit: 'HOURS')
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
    RSPEC_PROCESSES = configuration.getInteger('rspecq-processes')
    GERRIT_CHANGE_ID = getChangeId()

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

    BASE_RUNNER_PREFIX = configuration.buildRegistryPath('base-runner')
    CASSANDRA_PREFIX = configuration.buildRegistryPath('cassandra-migrations')
    DYNAMODB_PREFIX = configuration.buildRegistryPath('dynamodb-migrations')
    KARMA_BUILDER_PREFIX = configuration.buildRegistryPath('karma-builder')
    KARMA_RUNNER_PREFIX = configuration.buildRegistryPath('karma-runner')
    LINTERS_RUNNER_PREFIX = configuration.buildRegistryPath('linters-runner')
    POSTGRES_PREFIX = configuration.buildRegistryPath('postgres-migrations')
    RUBY_RUNNER_PREFIX = configuration.buildRegistryPath('ruby-runner')
    YARN_RUNNER_PREFIX = configuration.buildRegistryPath('yarn-runner')
    WEBPACK_BUILDER_PREFIX = configuration.buildRegistryPath('webpack-builder')
    WEBPACK_CACHE_PREFIX = configuration.buildRegistryPath('webpack-cache')

    IMAGE_CACHE_BUILD_SCOPE = configuration.gerritChangeNumber()
    IMAGE_CACHE_MERGE_SCOPE = configuration.gerritBranchSanitized()
    IMAGE_CACHE_UNIQUE_SCOPE = "${imageTagVersion()}-$TAG_SUFFIX"

    CASSANDRA_IMAGE_TAG = "$CASSANDRA_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    DYNAMODB_IMAGE_TAG = "$DYNAMODB_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_IMAGE_TAG = "$POSTGRES_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    WEBPACK_BUILDER_IMAGE = "$WEBPACK_BUILDER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    WEBPACK_CACHE_IMAGE = "$WEBPACK_CACHE_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"

    CASSANDRA_MERGE_IMAGE = "$CASSANDRA_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-${env.RSPEC_PROCESSES ?: '4'}"
    DYNAMODB_MERGE_IMAGE = "$DYNAMODB_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-${env.RSPEC_PROCESSES ?: '4'}"
    KARMA_RUNNER_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    KARMA_MERGE_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_MERGE_SCOPE"
    LINTERS_RUNNER_IMAGE = "$LINTERS_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    POSTGRES_MERGE_IMAGE = "$POSTGRES_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-${env.RSPEC_PROCESSES ?: '4'}"

    // This is primarily for the plugin build
    // for testing canvas-lms changes against plugin repo changes
    CANVAS_BUILDS_REFSPEC = getCanvasBuildsRefspec()
    CANVAS_LMS_REFSPEC = getCanvasLmsRefspec()
    DOCKER_WORKDIR = getDockerWorkDir()
    LOCAL_WORKDIR = getLocalWorkDir()

    // TEST_CACHE_CLASSES is consumed by config/environments/test.rb
    // to decide whether to allow class reloading or not.
    // in local development we usually want this unset or set to '0' because
    // we want spring to be able to reload classes between
    // spec runs, but this is expensive when running all the
    // specs for the build.  EVERYWHERE in the build we want
    // to be able to cache classes because they don't change while the build
    // is running and should never be reloaded.
    TEST_CACHE_CLASSES = '1'
  }

  stages {
    stage('Environment') {
      steps {
        script {
          lock(label: 'canvas_build_global_mutex', quantity: 1) {
            timeout(60) {
              node('master') {
                // For builds like Rails 6.1 prototype, we want to be able to see the build link, but
                // not have Gerrit vote on it. This isn't currently supported through the Gerrit Trigger
                // plugin, because the Build Started message always votes and will clear the original
                // vote. Work around this by disabling the build start message and setting EMULATE_BUILD_START=1
                // in the Build Parameters section.
                // https://issues.jenkins.io/browse/JENKINS-28339
                if (configuration.getBoolean('emulate-build-start', 'false')) {
                  gerrit.submitReview("", "Build Started ${RUN_DISPLAY_URL}")
                }

                // Skip builds for patchsets uploaded by svc.cloudjenkins, these are usually translation updates.
                if (env.GERRIT_PATCHSET_UPLOADER_EMAIL == 'svc.cloudjenkins@instructure.com' && !configuration.isChangeMerged()) {
                  currentBuild.result = 'ABORTED'
                  error('No pre-merge builds for Service Cloud Jenkins user.')
                }

                if (configuration.skipCi()) {
                  currentBuild.result = 'NOT_BUILT'
                  gerrit.submitLintReview('-2', 'Build not executed due to [skip-ci] flag')
                  error '[skip-ci] flag enabled: skipping the build'
                  return
                } else if (extendedStage.isAllowStagesFilterUsed() || extendedStage.isIgnoreStageResultsFilterUsed() || extendedStage.isSkipStagesFilterUsed()) {
                  gerrit.submitLintReview('-2', 'One or more build flags causes a subset of the build to be run')
                } else if (setupStage.hasGemOverrides()) {
                  gerrit.submitLintReview('-2', 'One or more build flags causes the build to be run against an unmerged gem version override')
                } else {
                  gerrit.submitLintReview('0')
                }
              }

              if (isStartedByUser()) {
                env.GERRIT_PATCHSET_REVISION = git.getRevisionHash()
                buildParameters += string(name: 'GERRIT_PATCHSET_REVISION', value: "${env.GERRIT_PATCHSET_REVISION}")
              }

              // Ensure that all build flags are compatible.
              if (configuration.getBoolean('change-merged') && configuration.isValueDefault('build-registry-path')) {
                error 'Manually triggering the change-merged build path must be combined with a custom build-registry-path'
                return
              }

              maybeSlackSendRetrigger()

              def postBuildHandler = [
                onStageEnded: { stageName, stageConfig, result ->
                  buildSummaryReport.addFailureRun('Main Build', currentBuild)
                  postFn(stageConfig.status())
                }
              ]

              extendedStage('Root').hooks(postBuildHandler).obeysAllowStages(false).reportTimings(false).execute {
                def rootStages = [:]

                buildParameters += string(name: 'CANVAS_BUILDS_REFSPEC', value: "${env.CANVAS_BUILDS_REFSPEC}")
                buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
                buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
                buildParameters += string(name: 'RUBY', value: "${env.RUBY}")
                buildParameters += string(name: 'CANVAS_RAILS', value: "${env.CANVAS_RAILS}")

                // If modifying any of our Jenkinsfiles set JENKINSFILE_REFSPEC for sub-builds to use Jenkinsfiles in
                // the gerrit rather than master. Stable branches also need to check out the JENKINSFILE_REFSPEC to prevent
                // the job default from pulling master.
                if (env.GERRIT_PROJECT == 'canvas-lms' && env.JOB_NAME.endsWith('Jenkinsfile')) {
                  buildParameters += string(name: 'JENKINSFILE_REFSPEC', value: "${env.GERRIT_REFSPEC}")
                } else if (env.GERRIT_PROJECT == 'canvas-lms' && env.JOB_NAME.endsWith('stable')) {
                  buildParameters += string(name: 'JENKINSFILE_REFSPEC', value: "${env.GERRIT_REFSPEC}")
                }

                if (env.GERRIT_PROJECT != 'canvas-lms') {
                  // the plugin builds require the canvas lms refspec to be different. so only
                  // set this refspec if the main build is requesting it to be set.
                  // NOTE: this is only being set in main-from-plugin build. so main-canvas wont run this.
                  buildParameters += string(name: 'CANVAS_LMS_REFSPEC', value: env.CANVAS_LMS_REFSPEC)
                }

                extendedStage('Builder').nodeRequirements(label: 'canvas-docker', podTemplate: null).obeysAllowStages(false).reportTimings(false).queue(rootStages) {
                  extendedStage('Setup')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .timeout(2)
                    .execute { setupStage() }

                  extendedStage('Rebase')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .required(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms')
                    .timeout(2)
                    .execute { rebaseStage() }

                  extendedStage(filesChangedStage.STAGE_NAME)
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .timeout(2)
                    .execute(filesChangedStage.&call)

                  extendedStage('Build Docker Image (Pre-Merge)')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .required(configuration.isChangeMerged())
                    .timeout(20)
                    .execute(buildDockerImageStage.&premergeCacheImage)

                  extendedStage('Build Docker Image')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .timeout(20)
                    .execute {
                      buildDockerImageStage.patchsetImage('''
                        diffFrom=$(git --git-dir $LOCAL_WORKDIR/.git rev-parse $GERRIT_PATCHSET_REVISION^1)
                        docker run -dt --name general-build-container --volume $(pwd)/$LOCAL_WORKDIR/.git:$DOCKER_WORKDIR/.git -e RAILS_ENV=test $PATCHSET_TAG bash -c "bin/rails runner \"true\" && sleep infinity"
                        docker exec -dt \
                                      -e CRYSTALBALL_DIFF_FROM=$diffFrom \
                                      -e CRYSTALBALL_DIFF_TO=$GERRIT_PATCHSET_REVISION \
                                      -e CRYSTALBALL_REPO_PATH=$DOCKER_WORKDIR \
                                      general-build-container bundle exec crystalball --dry-run
                        docker exec -t general-build-container ps aww
                      ''')
                    }

                  extendedStage(RUN_MIGRATIONS_STAGE)
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .timeout(10)
                    .execute { runMigrationsStage() }

                  extendedStage('Generate Crystalball Prediction')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .required(!configuration.isChangeMerged() && env.GERRIT_REFSPEC != "refs/heads/master")
                    .timeout(2)
                    .execute {
                      try {
                        /* groovylint-disable-next-line GStringExpressionWithinString */
                        sh '''#!/bin/bash
                          set -ex

                          while docker exec -t general-build-container ps aww | grep crystalball; do
                            sleep 0.1
                          done

                          docker cp \$(docker ps -qa -f name=general-build-container):/usr/src/app/crystalball_spec_list.txt ./tmp/crystalball_spec_list.txt
                        '''
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_spec_list.txt'

                        sh 'grep ":timestamp:" crystalball_map.yml | sed "s/:timestamp: //g" > ./tmp/crystalball_map_version.txt'
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_map_version.txt'
                      /* groovylint-disable-next-line CatchException */
                      } catch (Exception e) {
                        // default to full run of specs
                        sh 'echo -n "." > tmp/crystalball_spec_list.txt'
                        sh 'echo -n "broken map, defaulting to run all tests" > tmp/crystalball_map_version.txt'

                        archiveArtifacts allowEmptyArchive: true, artifacts: 'tmp/crystalball_spec_list.txt, tmp/crystalball_map_version.txt'

                        slackSend(
                          channel: '#crystalball-noisy',
                          color: 'danger',
                          message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\nFailed to generate prediction!"
                        )
                      }
                    }

                  extendedStage('Locales Only Changes')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .required(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms' && sh(script: "${WORKSPACE}/build/new-jenkins/locales-changes.sh", returnStatus: true) == 0)
                    .execute {
                        gerrit.submitLintReview('-2', 'This commit contains only changes to config/locales/, this could be a bad sign!')
                      }

                  extendedStage('Webpack Bundle Size Check')
                    .hooks(buildSummaryReportHooks.call())
                    .obeysAllowStages(false)
                    .required(configuration.isChangeMerged())
                    .timeout(20)
                    .execute { webpackStage.&calcBundleSizes() }

                  extendedStage('Parallel Run Tests').obeysAllowStages(false).execute { stageConfig, buildConfig ->
                    def stages = [:]

                    extendedStage('Consumer Smoke Test').hooks(buildSummaryReportHooks.call()).queue(stages) {
                      sh 'build/new-jenkins/consumer-smoke-test.sh'
                    }

                    extendedStage(JS_BUILD_IMAGE_STAGE)
                      .hooks(buildSummaryReportHooks.call())
                      .queue(stages, buildDockerImageStage.&jsImage)

                    extendedStage(LINTERS_BUILD_IMAGE_STAGE)
                      .hooks(buildSummaryReportHooks.call())
                      .queue(stages, buildDockerImageStage.&lintersImage)

                    extendedStage('Run i18n:extract')
                      .hooks(buildSummaryReportHooks.call())
                      .required(configuration.isChangeMerged())
                      .queue(stages, buildDockerImageStage.&i18nExtract)

                    parallel(stages)
                  }
                }

                extendedStage("${filesChangedStage.STAGE_NAME} (Waiting for Dependencies)").obeysAllowStages(false).waitsFor(filesChangedStage.STAGE_NAME, 'Builder').queue(rootStages) { stageConfig, buildConfig ->
                  def nestedStages = [:]

                  extendedStage('Local Docker Dev Build')
                    .hooks(buildSummaryReportHooks.call())
                    .required(env.GERRIT_PROJECT == 'canvas-lms' && filesChangedStage.hasDockerDevFiles(buildConfig))
                    .queue(nestedStages, jobName: '/Canvas/test-suites/local-docker-dev-smoke', buildParameters: buildParameters)

                  parallel(nestedStages)
                }

                extendedStage('Javascript (Waiting for Dependencies)').obeysAllowStages(false).waitsFor(JS_BUILD_IMAGE_STAGE, 'Builder').queue(rootStages) {
                  def nestedStages = [:]

                  extendedStage('Javascript')
                    .hooks(buildSummaryReportHooks.withRunManifest(true))
                    .queue(nestedStages, jobName: '/Canvas/test-suites/JS', buildParameters: buildParameters + [
                      string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                    ])

                  parallel(nestedStages)
                }

                extendedStage('Linters (Waiting for Dependencies)').obeysAllowStages(false).waitsFor(LINTERS_BUILD_IMAGE_STAGE, 'Builder').queue(rootStages) { stageConfig, buildConfig ->
                  extendedStage('Linters - Dependency Check')
                    .nodeRequirements(label: 'canvas-docker', podTemplate: dependencyCheckStage.nodeRequirementsTemplate(), container: 'dependency-check')
                    .required(configuration.isChangeMerged())
                    .execute(dependencyCheckStage.queueTestStage())

                  extendedStage('Linters')
                    .hooks([onNodeReleasing: lintersStage.tearDownNode()])
                    .nodeRequirements(label: 'canvas-docker', podTemplate: lintersStage.nodeRequirementsTemplate())
                    .required(!configuration.isChangeMerged() && env.GERRIT_CHANGE_ID != '0')
                    .execute {
                      def nestedStages = [:]

                      callableWithDelegate(lintersStage.codeStage(nestedStages))()
                      callableWithDelegate(lintersStage.featureFlagStage(nestedStages, buildConfig))()
                      callableWithDelegate(lintersStage.groovyStage(nestedStages, buildConfig))()
                      callableWithDelegate(lintersStage.masterBouncerStage(nestedStages))()
                      callableWithDelegate(lintersStage.yarnStage(nestedStages, buildConfig))()

                      parallel(nestedStages)
                    }
                }

                extendedStage("${RUN_MIGRATIONS_STAGE} (Waiting for Dependencies)").obeysAllowStages(false).waitsFor(RUN_MIGRATIONS_STAGE, 'Builder').queue(rootStages) { stageConfig, buildConfig ->
                  def nestedStages = [:]

                  extendedStage('CDC Schema Check')
                    .hooks(buildSummaryReportHooks.call())
                    .required(filesChangedStage.hasMigrationFiles(buildConfig))
                    .queue(nestedStages, jobName: '/Canvas/cdc-event-transformer-master', buildParameters: buildParameters + [
                      string(name: 'CANVAS_LMS_IMAGE_PATH', value: "${env.PATCHSET_TAG}"),
                    ])

                  extendedStage('Contract Tests')
                    .hooks(buildSummaryReportHooks.call())
                    .queue(nestedStages, jobName: '/Canvas/test-suites/contract-tests', buildParameters: buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                    ])

                  // Trigger Crystalball map build if spec files were added or removed, will not vote on builds.
                  if (configuration.isChangeMerged() && filesChangedStage.hasNewDeletedSpecFiles(buildConfig)) {
                    build(wait: false, job: 'Canvas/helpers/crystalball-map')
                  }

                  extendedStage('Flakey Spec Catcher')
                    .hooks(buildSummaryReportHooks.call())
                    .required(!configuration.isChangeMerged() && filesChangedStage.hasSpecFiles(buildConfig) || configuration.forceFailureFSC() == '1')
                    .queue(nestedStages, jobName: '/Canvas/test-suites/flakey-spec-catcher', buildParameters: buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                    ])

                  extendedStage('Vendored Gems')
                    .hooks(buildSummaryReportHooks.call())
                    .queue(nestedStages, jobName: '/Canvas/test-suites/vendored-gems', buildParameters: buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                    ])

                  extendedStage('RspecQ Tests')
                    .hooks(buildSummaryReportHooks.withRunManifest())
                    .queue(nestedStages, jobName: '/Canvas/test-suites/test-queue', buildParameters: buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                      string(name: 'SKIP_CRYSTALBALL', value: "${env.SKIP_CRYSTALBALL || setupStage.hasGemOverrides()}"),
                      string(name: 'UPSTREAM_TAG', value: "${env.BUILD_TAG}"),
                      string(name: 'UPSTREAM', value: "${env.JOB_NAME}"),
                    ])

                  parallel(nestedStages)
                }

                parallel(rootStages)
              }
            }
          }
        } // script
      } // steps
    } // environment
  } // stages
} // pipeline
