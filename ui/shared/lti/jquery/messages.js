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

import {findDomForWindow} from './util'
import {
  NAVIGATION_MESSAGE as MENTIONS_NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE as MENTIONS_INPUT_CHANGE_MESSAGE,
  SELECTION_MESSAGE as MENTIONS_SELECTION_MESSAGE
} from '../../rce/plugins/canvas_mentions/constants'

// page-global storage for data relevant to LTI postMessage events
const ltiState = {}

const SUBJECT_ALLOW_LIST = [
  'lti.enableScrollEvents',
  'lti.fetchWindowSize',
  'lti.frameResize',
  'lti.removeUnloadMessage',
  'lti.resourceImported',
  'lti.screenReaderAlert',
  'lti.scrollToTop',
  'lti.setUnloadMessage',
  'lti.showModuleNavigation',
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

async function ltiMessageHandler(e) {
  if (e.data.source && e.data.source.includes('react-devtools')) {
    return
  }

  let message
  try {
    message = typeof e.data === 'string' ? JSON.parse(e.data) : e.data
  } catch (err) {
    // unparseable message may not be meant for our handlers
    return
  }

  // look at messageType for backwards compatibility
  const subject = message.subject || message.messageType

  if (SUBJECT_IGNORE_LIST.includes(subject) || !SUBJECT_ALLOW_LIST.includes(subject)) {
    return false
  }

  try {
    const handlerModule = await import(`./post_message/${subject}.js`)
    handlerModule.default({message, iframe: findDomForWindow(e.source), event: e})
    return true
  } catch (error) {
    console.error(`Error loading or executing message handler for "${subject}"`, error)
  }
}

function monitorLtiMessages() {
  window.addEventListener('message', e => {
    if (e.data !== '') ltiMessageHandler(e)
  })
}

export {ltiState, SUBJECT_ALLOW_LIST, SUBJECT_IGNORE_LIST, ltiMessageHandler, monitorLtiMessages}
