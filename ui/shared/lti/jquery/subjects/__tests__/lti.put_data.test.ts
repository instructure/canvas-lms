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

import * as platformStorage from '../../platform_storage'
import type {ResponseMessages} from '../../response_messages'
import handler from '../lti.put_data'

jest.mock('../../platform_storage')

const mockedPlatformStorage = platformStorage as jest.Mocked<typeof platformStorage>

describe('lti.put_data handler', () => {
  let message: Parameters<typeof handler>[0]['message']
  let responseMessages: ResponseMessages
  let event: MessageEvent

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendResponse: jest.fn(),
      sendSuccess: jest.fn(),
      sendError: jest.fn(),
      sendGenericError: jest.fn(),
      sendWrongOriginError: jest.fn(),
      sendUnsupportedSubjectError: jest.fn(),
      sendUnauthorizedError: jest.fn(),
      isResponse: jest.fn(),
    }
    event = new MessageEvent('message', {
      origin: 'http://example.com',
    })
    mockedPlatformStorage.clearData.mockImplementation(() => {})
    mockedPlatformStorage.putData.mockImplementation(() => {})
  })

  afterEach(() => {
    mockedPlatformStorage.clearData.mockRestore()
    mockedPlatformStorage.putData.mockRestore()
  })

  describe('when key is not present', () => {
    beforeEach(() => {
      // This code is used from JavaScript, so while we might know that the key has to be present,
      // some JavaScript code might not know that.
      // @ts-expect-error
      message = {message_id: 'any', value: 'world'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'key' field",
      )
    })
  })

  describe('when message_id is not present', () => {
    beforeEach(() => {
      // This code is used from JavaScript, so while we might know that the message_id has to be present,
      // some JavaScript code might not know that.
      // @ts-expect-error
      message = {key: 'hello', value: 'world'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'message_id' field",
      )
    })
  })

  describe('when value is not present', () => {
    beforeEach(() => {
      // This code is used from JavaScript, so while we might know that the value has to be present,
      // some JavaScript code might not know that.
      // @ts-expect-error
      message = {key: 'hello', message_id: 'any'}
    })

    it('clears data from platform storage', () => {
      handler({message, responseMessages, event})
      expect(platformStorage.clearData).toHaveBeenCalled()
    })

    it('sends response postMessage with only key', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendResponse).toHaveBeenCalledWith({key: 'hello'})
    })
  })

  describe('with correct values', () => {
    beforeEach(() => {
      message = {key: 'hello', value: 'world', message_id: 'any'}
    })

    it('puts data in platform storage', () => {
      handler({message, responseMessages, event})
      expect(platformStorage.putData).toHaveBeenCalledWith(event.origin, message.key, message.value)
    })

    it('sends response postMessage with key and value', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendResponse).toHaveBeenCalledWith({key: 'hello', value: 'world'})
    })
  })

  describe('when platform storage throws an error with a code', () => {
    const errorMessage = 'message'
    const code = 'code'

    beforeEach(() => {
      message = {key: 'hello', value: 'world', message_id: 'any'}
      mockedPlatformStorage.putData.mockRestore()
      mockedPlatformStorage.putData.mockImplementation(() => {
        throw {
          code,
          message: errorMessage,
        }
      })
    })

    it('includes code in error response postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendError).toHaveBeenCalledWith(code, errorMessage)
    })
  })
})
