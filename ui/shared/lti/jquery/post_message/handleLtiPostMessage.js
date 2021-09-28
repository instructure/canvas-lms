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

import {
  NAVIGATION_MESSAGE as MENTIONS_NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE as MENTIONS_INPUT_CHANGE_MESSAGE,
  SELECTION_MESSAGE as MENTIONS_SELECTION_MESSAGE
} from '../../../rce/plugins/canvas_mentions/constants'

const SUBJECT_ALLOW_LIST = [
  'requestFullWindowLaunch',
  'lti.resourceImported',
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

const handleLtiPostMessage = async e => {
  const {messageType, data} = e.data
  let handler

  if (SUBJECT_IGNORE_LIST.includes(messageType)) {
    // These messages are handled elsewhere
    return false
  } else if (!SUBJECT_ALLOW_LIST.includes(messageType)) {
    // Enforce messageType allowlist -- unknown type
    // eslint-disable-next-line no-console
    console.error(`invalid messageType: ${messageType}`)
    return false
  }

  try {
    const handlerModule = await import(`./${messageType}.js`)
    handler = handlerModule.default
    handler(data)
    return true
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(`Error loading or executing message handler for "${messageType}"`, error)
  }
}

export default handleLtiPostMessage
