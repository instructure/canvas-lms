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

import {
  sendResponse,
  sendErrorResponse,
  sendGenericErrorResponse,
  sendBadRequestResponse,
  sendWrongOriginResponse,
  sendUnsupportedSubjectResponse,
  sendSuccess
} from '../response_messages'

describe('response_messages', () => {
  const postMessageMock = jest.fn()
  let params

  beforeEach(() => {
    params = {
      targetWindow: {postMessage: postMessageMock},
      origin: 'http://tool.test',
      subject: 'subject'
    }
    postMessageMock.mockRestore()
  })

  function expectPostMessageContents(contents, origin = expect.any(String)) {
    expect(postMessageMock).toHaveBeenCalledWith(expect.objectContaining(contents), origin)
  }

  describe('sendResponse', () => {
    it('appends .response to the subject', () => {
      sendResponse(params)
      expectPostMessageContents({subject: 'subject.response'})
    })

    describe('when message_id is present', () => {
      const message_id = 'message_id'

      beforeEach(() => {
        params.message_id = message_id
      })

      it('includes message_id in response', () => {
        sendResponse(params)
        expectPostMessageContents({message_id})
      })
    })

    describe('when targetWindow does not exist', () => {
      beforeEach(() => {
        delete params.targetWindow
        jest.spyOn(console, 'error').mockImplementation()
      })

      afterEach(() => {
        // eslint-disable-next-line no-console
        console.error.mockRestore()
      })

      it('logs an error to the console', () => {
        sendResponse(params)
        // eslint-disable-next-line no-console
        expect(console.error).toHaveBeenCalled()
      })
    })

    it('sends response to the given origin', () => {
      sendResponse(params)
      expectPostMessageContents({}, 'http://tool.test')
    })

    describe('when contents parameter is passed', () => {
      const contents = {hello: 'world'}
      beforeEach(() => {
        params.contents = contents
      })

      it('merges contents into response', () => {
        sendResponse(params)
        expectPostMessageContents(contents)
      })
    })
  })

  describe('sendSuccess', () => {
    beforeEach(() => {
      params.message_id = 'message_id'
    })

    it('only sends subject and message_id', () => {
      sendSuccess(params)
      expect(Object.keys(postMessageMock.mock.calls[0][0])).toEqual(['subject', 'message_id'])
    })
  })

  function expectCodeAndMessageInError({subject, code, message}) {
    beforeEach(() => {
      if (code) {
        params.code = code
      }
      if (message) {
        params.message = message
      }
    })

    it('includes code and message in error', () => {
      subject(params)
      const response = {}
      if (code) {
        response.code = code
      }
      if (message) {
        response.message = message
      }
      expectPostMessageContents({error: expect.objectContaining(response)})
    })
  }

  describe('sendErrorResponse', () => {
    expectCodeAndMessageInError({
      subject: sendErrorResponse,
      code: 'error_code',
      message: 'error message'
    })
  })

  describe('sendGenericErrorResponse', () => {
    expectCodeAndMessageInError({
      subject: sendGenericErrorResponse,
      code: 'error',
      message: 'generic error message'
    })
  })

  describe('sendBadRequestResponse', () => {
    expectCodeAndMessageInError({
      subject: sendBadRequestResponse,
      code: 'bad_request',
      message: 'error message'
    })
  })

  describe('sendWrongOriginResponse', () => {
    expectCodeAndMessageInError({
      subject: sendWrongOriginResponse,
      code: 'wrong_origin'
    })
  })

  describe('sendUnsupportedSubjectResponse', () => {
    expectCodeAndMessageInError({
      subject: sendUnsupportedSubjectResponse,
      code: 'unsupported_subject'
    })
  })
})
