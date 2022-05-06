/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/* eslint no-console: 0 */

import {
  NAVIGATION_MESSAGE as MENTIONS_NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE as MENTIONS_INPUT_CHANGE_MESSAGE,
  SELECTION_MESSAGE as MENTIONS_SELECTION_MESSAGE
} from '../../rce/plugins/canvas_mentions/constants'
import buildResponseMessages from './response_messages'

// page-global storage for data relevant to LTI postMessage events
const ltiState = {}

const SUBJECT_ALLOW_LIST = [
  'lti.enableScrollEvents',
  'lti.fetchWindowSize',
  'lti.frameResize',
  'lti.hideRightSideWrapper',
  'lti.removeUnloadMessage',
  'lti.resourceImported',
  'lti.screenReaderAlert',
  'lti.scrollToTop',
  'lti.setUnloadMessage',
  'lti.showAlert',
  'lti.showModuleNavigation',
  'org.imsglobal.lti.capabilities',
  'org.imsglobal.lti.get_data',
  'org.imsglobal.lti.put_data',
  'requestFullWindowLaunch',
  'toggleCourseNavigationMenu'
]

// These are handled elsewhere so ignore them
const SUBJECT_IGNORE_LIST = [
  'A2ExternalContentReady',
  'LtiDeepLinkingResponse',
  MENTIONS_NAVIGATION_MESSAGE,
  MENTIONS_INPUT_CHANGE_MESSAGE,
  MENTIONS_SELECTION_MESSAGE
]

async function ltiMessageHandler(e, platformStorageFeatureFlag = false) {
  if (e.data.source && e.data.source.includes('react-devtools')) {
    return false
  }

  let message
  try {
    message = typeof e.data === 'string' ? JSON.parse(e.data) : e.data
  } catch (err) {
    // unparseable message may not be meant for our handlers
    return false
  }

  // look at messageType for backwards compatibility
  const subject = message.subject || message.messageType
  const responseMessages = buildResponseMessages({
    targetWindow: e.source,
    origin: e.origin,
    subject,
    message_id: message.message_id
  })

  if (SUBJECT_IGNORE_LIST.includes(subject)) {
    // These messages are handled elsewhere
    return false
  } else if (!SUBJECT_ALLOW_LIST.includes(subject)) {
    // Enforce subject allowlist -- unknown type
    if (platformStorageFeatureFlag) {
      responseMessages.sendUnsupportedSubjectError()
    }
    return false
  }

  // temporary: ignore LTI Platform Storage messages when feature flag is off
  if (!platformStorageFeatureFlag && subject.includes('org.imsglobal.lti')) {
    return false
  }

  try {
    const handlerModule = await import(`./subjects/${subject}.js`)
    const hasSentResponse = handlerModule.default({
      message,
      event: e,
      responseMessages
    })
    if (!hasSentResponse && platformStorageFeatureFlag) {
      responseMessages.sendSuccess()
    }
    return true
  } catch (error) {
    console.error(`Error loading or executing message handler for "${subject}": ${error}`)
    if (platformStorageFeatureFlag) {
      responseMessages.sendGenericError(error.message)
    }
    return false
  }
}

let hasListener = false

function monitorLtiMessages() {
  const platformStorageFeatureFlag = ENV?.FEATURES?.lti_platform_storage
  const cb = e => {
    if (e.data !== '') ltiMessageHandler(e, platformStorageFeatureFlag)
  }
  if (!hasListener) {
    window.addEventListener('message', cb)
    hasListener = true
  }
}

export {ltiState, SUBJECT_ALLOW_LIST, SUBJECT_IGNORE_LIST, ltiMessageHandler, monitorLtiMessages}
