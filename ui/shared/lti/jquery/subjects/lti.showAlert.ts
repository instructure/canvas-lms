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

import $ from '@canvas/rails-flash-notifications'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {LtiMessageHandler} from '../lti_message_handler'

const I18n = useI18nScope('ltiMessages')

const showAlert: LtiMessageHandler<{
  body: unknown
  title?: string
  alertType?: string
}> = ({message, responseMessages}) => {
  if (!message.body) {
    responseMessages.sendBadRequestError("Missing required 'body' field")
    return true
  }

  const {title, alertType, body} = message
  const contents = typeof body === 'string' ? body : JSON.stringify(body)
  const toolName = title || $('iframe[data-lti-launch]').attr('title') || I18n.t('External Tool')
  const displayMessage = `${toolName}: ${contents}`

  switch (alertType || 'success') {
    case 'success':
      $.flashMessageSafe(displayMessage)
      break
    case 'warning':
      $.flashWarningSafe(displayMessage)
      break
    case 'error':
      $.flashErrorSafe(displayMessage)
      break
    default:
      responseMessages.sendBadRequestError("Unsupported value for 'alertType' field")
      return true
  }
  responseMessages.sendSuccess()
  return true
}

export default showAlert
