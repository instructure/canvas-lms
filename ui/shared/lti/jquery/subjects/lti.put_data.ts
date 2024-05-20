/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {clearData, putData} from '../platform_storage'
import type {LtiMessageHandler} from '../lti_message_handler'
import {getKey} from '../util'

const handler: LtiMessageHandler<{
  key: string
  value: string
  message_id: string
}> = ({message, responseMessages, event}) => {
  const {key, value, message_id} = message

  if (!key) {
    responseMessages.sendBadRequestError("Missing required 'key' field")
    return true
  }

  if (!message_id) {
    responseMessages.sendBadRequestError("Missing required 'message_id' field")
    return true
  }

  if (value) {
    try {
      putData(event.origin, key, value)
      responseMessages.sendResponse({key, value})
    } catch (e: unknown) {
      const code = getKey('code', e)
      const message = getKey('message', e)
      responseMessages.sendError(
        typeof code === 'string' ? code : '',
        typeof message === 'string' ? message : undefined
      )
    }
  } else {
    clearData(event.origin, key)
    responseMessages.sendResponse({key})
  }
  return true
}

export default handler
