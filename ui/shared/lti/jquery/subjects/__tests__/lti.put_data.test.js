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

import handler from '../lti.put_data'
import * as platformStorage from '../../platform_storage'

jest.mock('../../platform_storage')

describe('lti.put_data handler', () => {
  let message
  let responseMessages
  let event

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendResponse: jest.fn(),
      sendError: jest.fn(),
    }
    event = {
      origin: 'http://example.com',
    }
    platformStorage.clearData.mockImplementation(() => {})
    platformStorage.putData.mockImplementation(() => {})
  })

  afterEach(() => {
    platformStorage.clearData.mockRestore()
    platformStorage.putData.mockRestore()
  })

  describe('when key is not present', () => {
    beforeEach(() => {
      message = {message_id: 'any', value: 'world'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'key' field"
      )
    })
  })

  describe('when message_id is not present', () => {
    beforeEach(() => {
      message = {key: 'hello', value: 'world'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'message_id' field"
      )
    })
  })

  describe('when value is not present', () => {
    beforeEach(() => {
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
      platformStorage.putData.mockRestore()
      platformStorage.putData.mockImplementation(() => {
        const e = new Error(errorMessage)
        e.code = code
        throw e
      })
    })

    it('includes code in error response postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendError).toHaveBeenCalledWith(code, errorMessage)
    })
  })
})
