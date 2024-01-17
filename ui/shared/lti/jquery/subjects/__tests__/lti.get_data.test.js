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

import handler from '../lti.get_data'
import * as platformStorage from '../../platform_storage'

jest.mock('../../platform_storage')

describe('lti.get_data handler', () => {
  let message
  let responseMessages
  let event
  const value = 'world!'

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendResponse: jest.fn(),
    }
    event = {
      origin: 'http://example.com',
    }
    platformStorage.getData.mockImplementation(() => value)
  })

  afterEach(() => {
    platformStorage.getData.mockRestore()
  })

  describe('when key is not present', () => {
    beforeEach(() => {
      message = {message_id: 'any'}
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
      message = {key: 'hello'}
    })

    it('sends bad request error postMessage', () => {
      handler({message, responseMessages, event})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'message_id' field"
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
