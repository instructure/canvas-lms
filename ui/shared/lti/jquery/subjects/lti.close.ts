/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {LtiMessageHandler} from '../lti_message_handler'

/**
 * Canvas pages that want to support the lti.close message and close the tool
 * launch iframe (usually in a modal) need to register a callback function
 * using `onLtiClosePostMessage(() => { ... })`.
 */
const handler: LtiMessageHandler = ({callback, responseMessages}) => {
  if (callback) {
    try {
      callback()
      responseMessages.sendSuccess()
    } catch (error) {
      responseMessages.sendError('tool did not close properly')
    }
  } else {
    responseMessages.sendUnsupportedSubjectError('placement does not support lti.close')
  }

  return true
}

export default handler
