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
def FILES_CHANGED_STAGE = 'Detect Files Changed'
def JS_BUILD_IMAGE_STAGE = 'Javascript (Build Image)'
def LINTERS_BUILD_IMAGE_STAGE = 'Linters (Build Image)'
def RUN_MIGRATIONS_STAGE = 'Run Migrations'

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

def getSummaryUrl() {
  return "${env.BUILD_URL}/build-summary-report"
}

def getDockerWorkDir() {
  return env.GERRIT_PROJECT == 'canvas-lms' ? '/usr/src/app' : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}"
}

def getLocalWorkDir() {
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
      }
    }
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
    def extra = "Please investigate the cause of the failure, and respond to this message with your diagnosis. If you need help, don't hesitate to tag @ oncall and our on call will assist in looking at the build. Further details of our post-merge failure process can be found at this <${configuration.getFailureWiki()}|link>. Thanks!"

    slackSend(
      channel: getSlackChannel(),
      color: 'danger',
      message: "${authorSegment}. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\n$extra"
    )
  }

  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'danger',
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> failed. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>."
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
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> succeeded. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>."
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

// These functions are intentionally pinned to GERRIT_EVENT_TYPE == 'change-merged' to ensure that real post-merge
// builds always run correctly. We intentionally ignore overrides for version pins, docker image paths, etc when
// running real post-merge builds.
// =========

def getSlackChannel() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

@groovy.transform.Field def CANVAS_BUILDS_REFSPEC_REGEX = /\[canvas\-builds\-refspec=(.+?)\]/

def getCanvasBuildsRefspec() {
  def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null

  if (env.GERRIT_EVENT_TYPE == 'change-merged' || !commitMessage || !(commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).find()) {
    return env.GERRIT_BRANCH.contains('stable/') ? env.GERRIT_BRANCH : 'master'
  }

  return (commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).findAll()[0][1]
}

@groovy.transform.Field def CANVAS_LMS_REFSPEC_REGEX = /\[canvas\-lms\-refspec=(.+?)\]/
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

    CASSANDRA_MERGE_IMAGE = "$CASSANDRA_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-$RSPEC_PROCESSES"
    DYNAMODB_MERGE_IMAGE = "$DYNAMODB_PREFIX:$IMAGE_CACHE_MERGE_SCOPE-$RSPEC_PROCESSES"
    KARMA_RUNNER_IMAGE = "$KARMA_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
    LINTERS_RUNNER_IMAGE = "$LINTERS_RUNNER_PREFIX:$IMAGE_CACHE_UNIQUE_SCOPE"
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
              gerrit.submitLintReview('-2', 'Build not executed due to [skip-ci] flag')
              error '[skip-ci] flag enabled: skipping the build'
              return
            } else if (extendedStage.isAllowStagesFilterUsed() || extendedStage.isIgnoreStageResultsFilterUsed() || extendedStage.isSkipStagesFilterUsed()) {
              gerrit.submitLintReview('-2', 'One or more build flags causes a subset of the build to be run')
            } else {
              gerrit.submitLintReview('0')
            }
          }

          // Ensure that all build flags are compatible.
          if (configuration.getBoolean('change-merged') && configuration.isValueDefault('build-registry-path')) {
            error 'Manually triggering the change-merged build path must be combined with a custom build-registry-path'
            return
          }

          reportToSplunk('is_kubernetes', [
            'value': configuration.isKubernetesEnabled(),
          ])

          maybeSlackSendRetrigger()

          def buildSummaryReportHooks = [
            onStageEnded: { stageName, _, buildResult ->
              if (buildResult) {
                buildSummaryReport.addFailureRun(stageName, buildResult)
                buildSummaryReport.addRunTestActions(stageName, buildResult)
                buildSummaryReport.setStageIgnored(stageName)
              }
            }
          ]

          def postBuildHandler = [
            onStageEnded: { _, stageConfig ->
              buildSummaryReport.addFailureRun('Main Build', currentBuild)
              postFn(stageConfig.status())
            }
          ]

          extendedStage('Root').hooks(postBuildHandler).obeysAllowStages(false).timings(false).execute {
            def rootStages = [:]

            buildParameters += string(name: 'CANVAS_BUILDS_REFSPEC', value: "${env.CANVAS_BUILDS_REFSPEC}")
            buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
            buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
            buildParameters += string(name: 'RUBY', value: "${env.RUBY}")
            buildParameters += string(name: 'CANVAS_RAILS6_0', value: '1')

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

            extendedStage('Builder').nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker').obeysAllowStages(false).timings(false).queue(rootStages) {
              // Use a nospot instance for now to avoid really bad UX. Jenkins currently will
              // wait for the current steps to complete (even wait to spin up a node), causing
              // extremely long wait times for a restart. Investigation in DE-166 / DE-158.
              extendedStage('Setup')
                .obeysAllowStages(false)
                .timeout(2)
                .execute({ setupStage() })

              extendedStage(FILES_CHANGED_STAGE)
                .obeysAllowStages(false)
                .timeout(2)
                .execute { stageConfig ->
                  stageConfig.value('dockerDevFiles', git.changedFiles(dockerDevFiles, 'HEAD^'))
                  stageConfig.value('migrationFiles', sh(script: 'build/new-jenkins/check-for-migrations.sh', returnStatus: true) == 0)

                  dir(env.LOCAL_WORKDIR) {
                    stageConfig.value('specFiles', sh(script: '${WORKSPACE}/build/new-jenkins/spec-changes.sh', returnStatus: true) == 0)
                  }

                  // Remove the @tmp directory created by dir() for plugin builds, so bundler doesn't get confused.
                  // https://issues.jenkins.io/browse/JENKINS-52750
                  if (env.GERRIT_PROJECT != 'canvas-lms') {
                    sh "rm -vrf $LOCAL_WORKDIR@tmp"
                  }

                  distribution.stashBuildScripts()
                }

              extendedStage('Rebase')
                .obeysAllowStages(false)
                .required(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms')
                .timeout(2)
                .execute({ rebaseStage() })

              extendedStage('Build Docker Image (Pre-Merge)')
                .obeysAllowStages(false)
                .required(configuration.isChangeMerged())
                .timeout(20)
                .execute(buildDockerImageStage.&premergeCacheImage)

              extendedStage('Build Docker Image')
                .obeysAllowStages(false)
                .timeout(20)
                .execute(buildDockerImageStage.&patchsetImage)

              extendedStage(RUN_MIGRATIONS_STAGE)
                .obeysAllowStages(false)
                .timeout(10)
                .execute({ runMigrationsStage() })

              extendedStage('Parallel Run Tests').obeysAllowStages(false).execute { _, buildConfig ->
                def stages = [:]

                extendedStage('Consumer Smoke Test').queue(stages) {
                  sh 'build/new-jenkins/consumer-smoke-test.sh'
                }

                extendedStage(JS_BUILD_IMAGE_STAGE)
                  .queue(stages, buildDockerImageStage.&jsImage)

                extendedStage(LINTERS_BUILD_IMAGE_STAGE)
                  .queue(stages, buildDockerImageStage.&lintersImage)

                parallel(stages)
              }
            }

            extendedStage("${FILES_CHANGED_STAGE} (Waiting for Dependencies)").obeysAllowStages(false).waitsFor(FILES_CHANGED_STAGE, 'Builder').queue(rootStages) { _, buildConfig ->
              def nestedStages = [:]

              extendedStage('Local Docker Dev Build')
                .hooks(buildSummaryReportHooks)
                .required(env.GERRIT_PROJECT == 'canvas-lms' && buildConfig[FILES_CHANGED_STAGE].value('dockerDevFiles'))
                .queue(nestedStages, jobName: '/Canvas/test-suites/local-docker-dev-smoke', buildParameters: buildParameters)

              parallel(nestedStages)
            }

            extendedStage('Javascript (Waiting for Dependencies)').obeysAllowStages(false).waitsFor(JS_BUILD_IMAGE_STAGE, 'Builder').queue(rootStages) {
              def nestedStages = [:]

              extendedStage('Javascript (Jest)')
                .hooks(buildSummaryReportHooks)
                .queue(nestedStages, jobName: '/Canvas/test-suites/JS', buildParameters: buildParameters + [
                  string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                  string(name: 'TEST_SUITE', value: 'jest'),
                ])

              extendedStage('Javascript (Coffeescript)')
                .hooks(buildSummaryReportHooks)
                .queue(nestedStages, jobName: '/Canvas/test-suites/JS', buildParameters: buildParameters + [
                  string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                  string(name: 'TEST_SUITE', value: 'coffee'),
                ])

              extendedStage('Javascript (Karma)')
                .hooks(buildSummaryReportHooks)
                .queue(nestedStages, jobName: '/Canvas/test-suites/JS', buildParameters: buildParameters + [
                  string(name: 'KARMA_RUNNER_IMAGE', value: env.KARMA_RUNNER_IMAGE),
                  string(name: 'TEST_SUITE', value: 'karma'),
                ])

              parallel(nestedStages)
            }

            extendedStage('Linters (Waiting for Dependencies)').obeysAllowStages(false).waitsFor(LINTERS_BUILD_IMAGE_STAGE, 'Builder').queue(rootStages) {
              extendedStage('Linters - Dependency Check')
                .hooks([onNodeAcquired: lintersStage.&setupNode])
                .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
                .required(configuration.isChangeMerged())
                .execute(lintersStage.&dependencyCheckStage)

              extendedStage('Linters')
                .hooks([onNodeAcquired: lintersStage.&setupNode, onNodeReleasing: lintersStage.&tearDownNode])
                .nodeRequirements(label: 'canvas-docker', podTemplate: libraryResource('/pod_templates/docker_base.yml'), container: 'docker')
                .required(!configuration.isChangeMerged())
                .execute {
                  def nestedStages = [:]

                  extendedStage('Linters - Code')
                    .queue(nestedStages, lintersStage.&codeStage)

                  extendedStage('Linters - Master Bouncer')
                    .required(env.MASTER_BOUNCER_RUN == '1')
                    .queue(nestedStages, lintersStage.&masterBouncerStage)

                  extendedStage('Linters - Webpack')
                    .queue(nestedStages, lintersStage.&webpackStage)

                  extendedStage('Linters - Yarn')
                    .required(env.GERRIT_PROJECT == 'canvas-lms' && git.changedFiles(['package.json', 'yarn.lock'], 'HEAD^'))
                    .queue(nestedStages, lintersStage.&yarnStage)

                  parallel(nestedStages)
                }
            }

            extendedStage("${RUN_MIGRATIONS_STAGE} (Waiting for Dependencies)").obeysAllowStages(false).waitsFor(RUN_MIGRATIONS_STAGE, 'Builder').queue(rootStages) { _, buildConfig ->
              def nestedStages = [:]

              extendedStage('CDC Schema Check')
                .hooks(buildSummaryReportHooks)
                .required(buildConfig[FILES_CHANGED_STAGE].value('migrationFiles'))
                .queue(nestedStages, jobName: '/Canvas/cdc-event-transformer-master', buildParameters: buildParameters + [
                  string(name: 'CANVAS_LMS_IMAGE_PATH', value: "${env.PATCHSET_TAG}"),
                ])

              extendedStage('Contract Tests')
                .hooks(buildSummaryReportHooks)
                .queue(nestedStages, jobName: '/Canvas/test-suites/contract-tests', buildParameters: buildParameters + [
                  string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                ])

              extendedStage('Flakey Spec Catcher')
                .hooks(buildSummaryReportHooks)
                .required(!configuration.isChangeMerged() && buildConfig[FILES_CHANGED_STAGE].value('specFiles') || configuration.forceFailureFSC() == '1')
                .queue(nestedStages, jobName: '/Canvas/test-suites/flakey-spec-catcher', buildParameters: buildParameters + [
                  string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                ])

              extendedStage('Vendored Gems')
                .hooks(buildSummaryReportHooks)
                .queue(nestedStages, jobName: '/Canvas/test-suites/vendored-gems', buildParameters: buildParameters + [
                  string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                  string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                  string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}"),
                ])

              distribution.addRSpecSuites(nestedStages)
              distribution.addSeleniumSuites(nestedStages)

              parallel(nestedStages)
            }

            parallel(rootStages)
          }
        }//script
      }//steps
    }//environment
  }//stages
}//pipeline
