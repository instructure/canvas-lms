/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import $ from 'jquery'
import toolConfigurationError from '../toolConfigurationError'

beforeAll(() => {
  $.flashError = jest.fn()
})

afterEach(() => {
  $.flashError.mockClear()
})

afterAll(() => {
  $.flashError.mockRestore()
})

const clientId = '1000000009'

const errorWithStatus = status => ({response: {status}})

describe('toolConfigurationError', () => {
  describe('when error statuss is 404', () => {
    beforeEach(() => {
      toolConfigurationError(errorWithStatus(404), clientId)
    })

    it('shows the "not found" error message', () => {
      expect($.flashError).toHaveBeenCalledWith(
        `Could not find an LTI configuration for client ID ${clientId}`
      )
    })
  })

  describe('when error statuss is 401', () => {
    beforeEach(() => {
      toolConfigurationError(errorWithStatus(401), clientId)
    })

    it('shows the "not enabled" error message', () => {
      expect($.flashError).toHaveBeenCalledWith(`The client ID ${clientId} is disabled`)
    })
  })

  describe('when error statuss is not 401 or 404', () => {
    beforeEach(() => {
      toolConfigurationError(errorWithStatus(500), clientId)
    })

    it('shows the generic error message', () => {
      expect($.flashError).toHaveBeenCalledWith(
        'An error occured while trying to find the LTI configuration'
      )
    })
  })
})
