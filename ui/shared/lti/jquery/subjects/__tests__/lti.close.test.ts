/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {ResponseMessages} from '../../response_messages'
import handler from '../lti.close'

describe('lti.close handler', () => {
  let callback: (() => void) | undefined
  let responseMessages: ResponseMessages
  const message: Parameters<typeof handler>[0]['message'] = {message_id: 'any'}
  const event = new MessageEvent('message', {
    origin: 'http://example.com',
  })

  const handle = () => handler({message, event, responseMessages, callback})

  beforeEach(() => {
    responseMessages = {
      sendUnsupportedSubjectError: jest.fn(),
      sendError: jest.fn(),
      sendSuccess: jest.fn(),
      sendBadRequestError: () => {},
      sendResponse: () => {},
      sendGenericError: () => {},
      sendWrongOriginError: () => {},
      sendUnauthorizedError: () => {},
      isResponse: () => true,
    }
  })
  describe('with no callback', () => {
    it('sends an unsupported subject error', () => {
      callback = undefined
      handle()

      expect(responseMessages.sendUnsupportedSubjectError).toHaveBeenCalledWith(
        'placement does not support lti.close',
      )
    })
  })

  describe('when callback raises error', () => {
    it('sends an error response', () => {
      callback = () => {
        throw new Error('test error')
      }
      handle()

      expect(responseMessages.sendError).toHaveBeenCalledWith('tool did not close properly')
    })
  })

  it('calls callback', () => {
    callback = jest.fn()

    handle()

    expect(callback).toHaveBeenCalled()
  })

  it('sends a success response', () => {
    callback = jest.fn()

    handle()

    expect(responseMessages.sendSuccess).toHaveBeenCalled()
  })
})
