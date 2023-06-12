/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

/**
 * Sends a failure message to the passed in channel. This is a detailed message,
 * typically meant for alerting a user or team of any build failures after a
 * post-merge build fails.
 *
 * @param channel The channel to send the failure message to
 * @param extraText Any additional info to send in the Slack message
 * @param pingAuthor Whether the patch-set author should be alerted to the failure or not
 */
def sendSlackFailureWithMsg(String channel, String extraText, boolean pingAuthor) {
  def branchSegment = env.GERRIT_BRANCH ? "[$env.GERRIT_BRANCH]" : ''
  def authorSlackId = env.GERRIT_EVENT_ACCOUNT_EMAIL ? slackUserIdFromEmail(email: env.GERRIT_EVENT_ACCOUNT_EMAIL, botUser: true, tokenCredentialId: 'slack-user-id-lookup') : ''
  def authorSlackMsg = authorSlackId ? "<@$authorSlackId>" : env.GERRIT_EVENT_ACCOUNT_NAME
  def authorSegment = env.GERRIT_CHANGE_URL ? "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${pingAuthor ? authorSlackMsg : authorSlackId}" : env.JOB_NAME

  slackSend(
    channel: channel,
    color: 'danger',
    message: "${authorSegment} failed against ${branchSegment}. Build <${getSummaryUrl()}|#${env.BUILD_NUMBER}>\n\n${extraText}"
  )
}

/*
 * Sends a small summary message about a failed build to the specified channel.
 * Includes links to relevant patchset, build, and how long the build took.
 *
 * @param channel The channel to send the message to.
 */
def sendSlackFailureWithDuration(String channel) {
  slackSend(
    channel: channel,
    color: 'danger',
    message: "${env.JOB_NAME} <${getSummaryUrl()}|#${env.BUILD_NUMBER}> failed. Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}>. (${currentBuild.durationString})"
  )
}

def getSummaryUrl() {
  return "${env.BUILD_URL}/build-summary-report"
}
