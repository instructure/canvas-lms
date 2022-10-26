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

const GENERIC_ERROR_CODE = 'error'
const UNSUPPORTED_SUBJECT_ERROR_CODE = 'unsupported_subject'
const WRONG_ORIGIN_ERROR_CODE = 'wrong_origin'
const BAD_REQUEST_ERROR_CODE = 'bad_request'

const buildResponseMessages = ({targetWindow, origin, subject, message_id, toolOrigin}) => {
  const sendResponse = (contents = {}) => {
    const message = {subject: `${subject}.response`}
    if (message_id) {
      message.message_id = message_id
    }
    if (toolOrigin) {
      message.toolOrigin = toolOrigin
    }
    if (targetWindow) {
      targetWindow.postMessage({...message, ...contents}, origin)
    } else {
      // eslint-disable-next-line no-console
      console.error('Error sending response postMessage: target window does not exist')
    }
  }

  const sendSuccess = () => {
    sendResponse({})
  }

  const sendError = (code, message) => {
    const error = {code}
    if (message) {
      error.message = message
    }
    sendResponse({error})
  }

  const sendGenericError = message => {
    sendError(GENERIC_ERROR_CODE, message)
  }

  const sendBadRequestError = message => {
    sendError(BAD_REQUEST_ERROR_CODE, message)
  }

  const sendWrongOriginError = () => {
    sendError(WRONG_ORIGIN_ERROR_CODE)
  }

  const sendUnsupportedSubjectError = () => {
    sendError(UNSUPPORTED_SUBJECT_ERROR_CODE)
  }

  const isResponse = message => !!message.data?.subject?.endsWith('.response')

  return {
    sendResponse,
    sendSuccess,
    sendError,
    sendGenericError,
    sendBadRequestError,
    sendWrongOriginError,
    sendUnsupportedSubjectError,
    isResponse,
  }
}

export default buildResponseMessages
