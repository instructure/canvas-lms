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

import buildResponseMessages from '../response_messages'

describe('response_messages', () => {
  const postMessageMock = jest.fn()
  let params
  let builder

  beforeEach(() => {
    resetBuilder()
    postMessageMock.mockRestore()
  })

  function resetBuilder(overrides = {}) {
    params = {
      targetWindow: {postMessage: postMessageMock},
      origin: 'http://tool.test',
      subject: 'subject',
      ...overrides,
    }
    builder = buildResponseMessages(params)
  }

  function expectPostMessageContents(contents, origin = expect.any(String)) {
    expect(postMessageMock).toHaveBeenCalledWith(expect.objectContaining(contents), origin)
  }

  describe('sendResponse', () => {
    it('appends .response to the subject', () => {
      builder.sendResponse()
      expectPostMessageContents({subject: 'subject.response'})
    })

    describe('when message_id is present', () => {
      const message_id = 'message_id'

      beforeEach(() => {
        resetBuilder({message_id})
      })

      it('includes message_id in response', () => {
        builder.sendResponse()
        expectPostMessageContents({message_id})
      })
    })

    describe('when sourceToolInfo is present', () => {
      const sourceToolInfo = {opaque: 'some opaque object'}

      beforeEach(() => {
        resetBuilder({sourceToolInfo})
      })

      it('includes sourceToolInfo in response', () => {
        builder.sendResponse()
        expectPostMessageContents({sourceToolInfo})
      })
    })

    describe('when targetWindow does not exist', () => {
      beforeEach(() => {
        resetBuilder({targetWindow: null})
        jest.spyOn(console, 'error').mockImplementation()
      })

      afterEach(() => {
        // eslint-disable-next-line no-console
        console.error.mockRestore()
      })

      it('logs an error to the console', () => {
        builder.sendResponse()
        // eslint-disable-next-line no-console
        expect(console.error).toHaveBeenCalled()
      })
    })

    it('sends response to the given origin', () => {
      builder.sendResponse()
      expectPostMessageContents({}, 'http://tool.test')
    })

    describe('when contents parameter is passed', () => {
      const contents = {hello: 'world'}

      it('merges contents into response', () => {
        builder.sendResponse(contents)
        expectPostMessageContents(contents)
      })
    })
  })

  describe('sendSuccess', () => {
    beforeEach(() => {
      resetBuilder({message_id: 'message_id'})
    })

    it('only sends subject and message_id', () => {
      builder.sendSuccess()
      expect(Object.keys(postMessageMock.mock.calls[0][0])).toEqual(['subject', 'message_id'])
    })
  })

  function expectCodeAndMessageInError({subject, code, message}) {
    it('includes code and message in error', () => {
      subject(builder)
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

  describe('sendError', () => {
    const code = 'error_code'
    const message = 'error message'

    expectCodeAndMessageInError({
      subject: builder => builder.sendError(code, message),
      code,
      message,
    })
  })

  describe('sendGenericError', () => {
    const message = 'generic error message'

    expectCodeAndMessageInError({
      subject: builder => builder.sendGenericError(message),
      code: 'error',
    })
  })

  describe('sendBadRequestError', () => {
    const message = 'bad request error message'

    expectCodeAndMessageInError({
      subject: builder => builder.sendBadRequestError(message),
      code: 'bad_request',
      message,
    })
  })

  describe('sendWrongOriginError', () => {
    expectCodeAndMessageInError({
      subject: builder => builder.sendWrongOriginError(),
      code: 'wrong_origin',
    })
  })

  describe('sendUnsupportedSubjectError', () => {
    expectCodeAndMessageInError({
      subject: builder => builder.sendUnsupportedSubjectError(),
      code: 'unsupported_subject',
    })
  })

  describe('sendUnsupportedSubjectError with message', () => {
    const message = 'wrong context'

    expectCodeAndMessageInError({
      subject: builder => builder.sendUnsupportedSubjectError(message),
      code: 'unsupported_subject',
    })
  })
})
