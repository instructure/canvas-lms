// @ts-nocheck
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

export interface ResponseMessages {
  sendResponse: (contents?: {}) => void
  sendSuccess: () => void
  sendError: (code: string, message?: string | undefined) => void
  sendGenericError: (message?: string | undefined) => void
  sendBadRequestError: (message: any) => void
  sendWrongOriginError: () => void
  sendUnsupportedSubjectError: (message?: string | undefined) => void
  isResponse: (message: any) => boolean
}

const buildResponseMessages = ({
  targetWindow,
  origin,
  subject,
  message_id,
  sourceToolInfo,
}: {
  targetWindow: Window | null
  origin: string
  subject: unknown
  message_id: unknown
  sourceToolInfo: unknown
}): ResponseMessages => {
  const sendResponse = (contents = {}) => {
    const message: {
      subject: string
      message_id?: unknown
      sourceToolInfo?: unknown
    } = {subject: `${subject}.response`}
    if (message_id) {
      message.message_id = message_id
    }
    if (sourceToolInfo) {
      message.sourceToolInfo = sourceToolInfo
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

  const sendError = (code: string, message?: string) => {
    const error: {code: string; message?: string} = {code}
    if (message) {
      error.message = message
    }
    sendResponse({error})
  }

  const sendGenericError = (message?: string) => {
    sendError(GENERIC_ERROR_CODE, message)
  }

  const sendBadRequestError = message => {
    sendError(BAD_REQUEST_ERROR_CODE, message)
  }

  const sendWrongOriginError = () => {
    sendError(WRONG_ORIGIN_ERROR_CODE)
  }

  const sendUnsupportedSubjectError = (message?: string) => {
    sendError(UNSUPPORTED_SUBJECT_ERROR_CODE, message)
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
