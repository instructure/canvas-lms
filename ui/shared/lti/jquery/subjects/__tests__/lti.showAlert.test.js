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

import handler from '../lti.showAlert'
import $ from '@canvas/rails-flash-notifications'

describe('lti.showAlert handler', () => {
  let message
  let responseMessages
  const body = 'Hello world!'

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendSuccess: jest.fn(),
    }
  })

  describe('when body is not present', () => {
    beforeEach(() => {
      message = {}
    })

    it('sends bad request postMessage', () => {
      handler({message, responseMessages})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Missing required 'body' field"
      )
    })
  })

  describe('when alertType is not supported', () => {
    beforeEach(() => {
      message = {body, alertType: 'bad'}
    })

    it('sends bad request postMessage', () => {
      handler({message, responseMessages})
      expect(responseMessages.sendBadRequestError).toHaveBeenCalledWith(
        "Unsupported value for 'alertType' field"
      )
    })
  })

  Object.entries({
    success: 'flashMessageSafe',
    warning: 'flashWarningSafe',
    error: 'flashErrorSafe',
  }).forEach(([alertType, method]) => {
    // eslint-disable-next-line jest/valid-describe
    describe(`when alertType is ${alertType}`, () => {
      beforeEach(() => {
        message = {body, alertType}
        jest.spyOn($, method)
      })

      afterEach(() => {
        $[method].mockRestore()
      })

      it('shows message', () => {
        handler({message, responseMessages})
        expect($[method]).toHaveBeenCalled()
      })

      it('sends success postMessage', () => {
        handler({message, responseMessages})
        expect(responseMessages.sendSuccess).toHaveBeenCalled()
      })
    })
  })

  describe('when title is provided', () => {
    const title = 'Tool Name'

    beforeEach(() => {
      message = {body, title}
      jest.spyOn($, 'flashMessageSafe')
    })

    afterEach(() => {
      $.flashMessageSafe.mockRestore()
    })

    it('uses title from message', () => {
      handler({message, responseMessages})
      expect($.flashMessageSafe).toHaveBeenCalledWith(expect.stringContaining(title))
    })
  })

  describe('when title is not found', () => {
    beforeEach(() => {
      message = {body}
      jest.spyOn($, 'flashMessageSafe')
    })

    afterEach(() => {
      $.flashMessageSafe.mockRestore()
    })

    it('uses title from message', () => {
      handler({message, responseMessages})
      expect($.flashMessageSafe).toHaveBeenCalledWith(expect.stringContaining('External Tool'))
    })
  })
})
