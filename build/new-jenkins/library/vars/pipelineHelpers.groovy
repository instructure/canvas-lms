/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import groovy.transform.Field

// Helper functions extracted from Jenkinsfile to reduce bytecode size

@Field final static GERRIT_CHANGE_ID_REGEX = /Change\-Id: (.*)/

def getDockerWorkDir() {
  if (env.GERRIT_PROJECT == 'qti_migration_tool') {
    return "/usr/src/app/vendor/${env.GERRIT_PROJECT}"
  }

  return env.GERRIT_PROJECT == 'canvas-lms' ? '/usr/src/app/' : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}/"
}

def getLocalWorkDir() {
  if (env.GERRIT_PROJECT == 'qti_migration_tool') {
    return "vendor/${env.GERRIT_PROJECT}"
  }

  return env.GERRIT_PROJECT == 'canvas-lms' ? '.' : "gems/plugins/${env.GERRIT_PROJECT}"
}

def getCanvasLmsRefspec() {
  def defaultBranch = env.GERRIT_BRANCH.contains('stable/') ? env.GERRIT_BRANCH : 'master'
  def defaultValue = "+refs/heads/$defaultBranch:refs/remotes/origin/$defaultBranch"

  return commitMessageFlag('canvas-lms-refspec') as String ?: defaultValue
}

def isStartedByUser() {
  return currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
}

def isPatchsetPublishable() {
  env.PUBLISH_PATCHSET_IMAGE == '1'
}

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

def isPatchsetRetriggered() {
  if (env.IS_AUTOMATIC_RETRIGGER == '1') {
    return true
  }

  def userCause = currentBuild.getBuildCauses('com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.GerritUserCause')

  return userCause && userCause.size() > 0 && userCause[0].shortDescription.contains('Retriggered')
}

def maybeSlackSendRetrigger() {
  if (configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'warning',
      message: "${getPatchsetPrefix()} by ${env.GERRIT_EVENT_ACCOUNT_EMAIL} has been re-triggered. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

def getSlackChannel() {
  return env.SLACK_CHANNEL_OVERRIDE ?: env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

def getSummaryUrl() {
  return "${env.BUILD_URL}/build-summary-report"
}

def getPatchsetPrefix() {
  return env.GERRIT_CHANGE_URL ? "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>" : env.JOB_NAME
}

def shouldPatchsetRetrigger() {
  return env.IS_AUTOMATIC_RETRIGGER == '0' && (
    configuration.isChangeMerged() && (commitMessageFlag('enable-automatic-retrigger') as Boolean)
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
    def extra = 'Oh no! Your build failed the post-merge checks. If you have a test failure not related to your build, please reach out to the owning team and ask them to skip or fix the failed test. Spec flakiness can be investigated <https://inst.splunkcloud.com/en-US/app/search/canvas_spec_tracker|here>. Otherwise, tag our @ oncall for help in diagnosing the build issue if it is unclear.'
    slackHelpers.sendSlackFailureWithMsg(getSlackChannel(), extra, true)
  } else {
    slackHelpers.sendSlackFailureWithDuration('#canvas_builds-noisy')
  }
}

def maybeSlackSendSuccess() {
  if (configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'good',
      message: "${getPatchsetPrefix()} succeeded on re-trigger. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>"
    )
  }

  slackSend(
    channel: '#canvas_builds-noisy',
    color: 'good',
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> succeeded. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>. (${currentBuild.durationString})"
  )
}

// Workspace cleanup helpers - extracted to reduce duplication across Jenkinsfiles

def cleanupWorkspace() {
  // Full workspace cleanup with history tracking and async deletion
  libraryScript.execute 'bash/docker-cleanup.sh'
  libraryScript.execute 'bash/print-env-excluding-secrets.sh'
  sh """#!/bin/bash
    set -ex
    echo "=== Build History ==="
    cat /tmp/canvas_build_history || true
    echo "\$RUN_DISPLAY_URL" >> /tmp/canvas_build_history
    mv "\$(pwd)" "\$(pwd)_pending_deletion_${currentBuild.startTimeInMillis}"
    mkdir -p "\$(pwd)"
    nohup rm -rf "\$(pwd)_pending_deletion_${currentBuild.startTimeInMillis}" &
  """
}

def cleanupDocker() {
  // Simple docker cleanup (for finally/post blocks)
  libraryScript.execute 'bash/docker-cleanup.sh'
}

def copyFromContainer(containerName, containerPath, workspacePath) {
  // Copy files from docker compose container to Jenkins workspace
  // Replaces the old podTemplateEmulation copyToWorkspace function
  //
  // Example: pipelineHelpers.copyFromContainer('canvas', '/usr/src/app/log/results', './log/results')

  // Ensure destination path exists (handles both files and directories)
  sh "mkdir -p \$(dirname ${workspacePath})"

  sh "docker compose -f ${env.COMPOSE_FILE} cp ${containerName}:${containerPath} ${workspacePath}"
}

// Configure Build stage helper - extracted to reduce Jenkinsfile bytecode
def configureBuildStage(buildParameters) {
  def canvasRailsOverrideValue = commitMessageFlag('canvas-rails') as String

  if (canvasRailsOverrideValue) {
    env.CANVAS_RAILS = canvasRailsOverrideValue
  }

  // Skip translation builds for patchsets uploaded by svc.cloudjenkins
  if (env.GERRIT_PATCHSET_UPLOADER_EMAIL == 'svc.cloudjenkins@instructure.com' && env.GERRIT_CHANGE_SUBJECT =~ /translation$/) {
    // Set status to NOT_BUILT for pre-merge builds
    if (!configuration.isChangeMerged()) {
      currentBuild.result = 'NOT_BUILT'
    }
    return buildParameters
  }

  if (commitMessageFlag('skip-ci') as Boolean) {
    currentBuild.result = 'NOT_BUILT'
    submitGerritReview('--label Lint-Review=-2', 'Build not executed due to [skip-ci] flag')
    error '[skip-ci] flag enabled: skipping the build'
  } else if ((commitMessageFlag('allow-stages') as String) || (commitMessageFlag('ignore-stage-results') as String) || (commitMessageFlag('skip-stages') as String)) {
    submitGerritReview('--label Lint-Review=-2', 'One or more build flags causes a subset of the build to be run')
  } else if (setupStage.hasGemOverrides()) {
    submitGerritReview('--label Lint-Review=-2', 'One or more build flags causes the build to be run against an unmerged gem or plugin version; if you need to coordinate merging multiple changes at once, you may want to edit the commit message to remove this flag after Jenkins has run tests')
  } else {
    submitGerritReview('--label Lint-Review=0')
  }

  if (isStartedByUser()) {
    env.GERRIT_PATCHSET_REVISION = git.getRevisionHash()
    buildParameters += string(name: 'GERRIT_PATCHSET_REVISION', value: "${env.GERRIT_PATCHSET_REVISION}")
  }

  // Ensure that all build flags are compatible.
  if (commitMessageFlag('change-merged') as Boolean && configuration.buildRegistryPath() == configuration.buildRegistryPathDefault()) {
    error 'Manually triggering the change-merged build path must be combined with a custom build-registry-path'
  }

  maybeSlackSendRetrigger()

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

  return buildParameters
}

// Post-build always block - extracted to reduce Jenkinsfile bytecode
def postBuildAlways() {
  def status = currentBuild.currentResult
  if (status == 'ABORTED') {
    def causes = currentBuild.getBuildCauses()
    def isUserAbort = causes.any { it.shortDescription?.contains('Aborted by user') }
    status = isUserAbort ? 'ABORTED_USER' : 'ABORTED_PATCHSET'
  }

  try {
    buildSummaryReport.addFailureRun('Main Build', currentBuild)
    buildSummaryReport.publishReport('Build Summary Report', status)

    if (isPatchsetPublishable()) {
      dockerUtils.tagRemote(env.PATCHSET_TAG, env.EXTERNAL_TAG)
    }

    if (status == 'SUCCESS' && configuration.isChangeMerged() && isPatchsetPublishable()) {
      dockerUtils.tagRemote(env.PATCHSET_TAG, env.MERGE_TAG)
      dockerUtils.tagRemote(env.DYNAMODB_IMAGE_TAG, env.DYNAMODB_MERGE_IMAGE)
      dockerUtils.tagRemote(env.POSTGRES_IMAGE_TAG, env.POSTGRES_MERGE_IMAGE)
      dockerUtils.tagRemote(env.KARMA_RUNNER_IMAGE, env.KARMA_MERGE_IMAGE)
    }

    if (isStartedByUser()) {
      submitGerritReview((status == 'SUCCESS' ? '--verified +1' : '--verified -1'), "${env.BUILD_URL}/build-summary-report/")
    }

    build(job: '/Canvas/helpers/junit-uploader', parameters: [
      string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
      string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
      string(name: 'SOURCE', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
    ], propagate: false, wait: false)
  } catch (Exception e) {
    echo "Post-build operations failed: ${e.message}"
  }
}

// Helper to run a test suite job with standard error tracking
def runTestSuite(stageName, jobPath, parameters) {
  def buildResult = null
  try {
    buildResult = build(
      job: jobPath,
      parameters: parameters,
      propagate: false
    )

    if (buildResult.result != 'SUCCESS') {
      error "${stageName} failed with status ${buildResult.result}"
    }
  } finally {
    // Track the sub-build's results, manifest, and aggregate data
    buildSummaryReport.trackSubBuild(stageName, buildResult)
  }
}

return this
