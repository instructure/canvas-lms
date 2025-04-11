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
import handler from '../lti.get_data'

jest.mock('../../platform_storage')

const mockPlatformStorage = platformStorage as jest.Mocked<typeof platformStorage>

describe('lti.get_data handler', () => {
  let message: Parameters<typeof handler>[0]['message']
  let responseMessages: ResponseMessages
  let event: MessageEvent
  const value = 'world!'

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
    mockPlatformStorage.getData.mockImplementation(() => value)
  })

  afterEach(() => {
    mockPlatformStorage.getData.mockRestore()
  })

  describe('when key is not present', () => {
    beforeEach(() => {
      // This code is used from JavaScript, so while we might know that the key has to be present,
      // some JavaScript code might not know that.
      // @ts-expect-error
      message = {message_id: 'any'}
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
      message = {key: 'hello'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'message_id' field",
      )
    })
  })

  describe('when key is present', () => {
    beforeEach(() => {
      message = {key: 'hello', message_id: 'any'}
    })

    it('gets data from platform storage', () => {
      handler({message, responseMessages, event})
      expect(platformStorage.getData).toHaveBeenCalledWith(event.origin, message.key)
    })

    it('sends response postMessage with key and value', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendResponse).toHaveBeenCalledWith({key: message.key, value})
    })
  })
})
