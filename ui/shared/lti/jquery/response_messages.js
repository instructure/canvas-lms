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

function sendResponse({targetWindow, origin, subject, message_id, contents}) {
  const message = {subject: `${subject}.response`}
  if (message_id) {
    message.message_id = message_id
  }
  if (targetWindow) {
    targetWindow.postMessage({...message, ...contents}, origin)
  } else {
    // eslint-disable-next-line no-console
    console.error('Error sending response postMessage: target window does not exist')
  }
}

function sendSuccess({targetWindow, origin, subject, message_id}) {
  sendResponse({targetWindow, origin, subject, message_id, contents: {}})
}

function sendErrorResponse({targetWindow, origin, subject, message_id, code, message}) {
  const error = {code}
  if (message) {
    error.message = message
  }
  sendResponse({targetWindow, origin, subject, message_id, contents: {error}})
}

function sendGenericErrorResponse({targetWindow, origin, subject, message_id, message}) {
  sendErrorResponse({targetWindow, origin, subject, message_id, message, code: GENERIC_ERROR_CODE})
}

function sendBadRequestResponse({targetWindow, origin, subject, message_id, message}) {
  sendErrorResponse({
    targetWindow,
    origin,
    subject,
    message_id,
    message,
    code: BAD_REQUEST_ERROR_CODE
  })
}

function sendUnsupportedSubjectResponse({targetWindow, origin, subject, message_id}) {
  sendErrorResponse({
    targetWindow,
    origin,
    subject,
    message_id,
    code: UNSUPPORTED_SUBJECT_ERROR_CODE
  })
}

function sendWrongOriginResponse({targetWindow, origin, subject, message_id}) {
  sendErrorResponse({targetWindow, origin, subject, message_id, code: WRONG_ORIGIN_ERROR_CODE})
}

export {
  sendResponse,
  sendSuccess,
  sendErrorResponse,
  sendGenericErrorResponse,
  sendBadRequestResponse,
  sendUnsupportedSubjectResponse,
  sendWrongOriginResponse
}
