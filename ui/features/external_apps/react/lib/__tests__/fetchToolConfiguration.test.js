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

import axios from '@canvas/axios'
import fetchToolConfiguration from '../fetchToolConfiguration'

const errorHandler = jest.fn()
const clientId = 10000000009
const showUrl = 'https://www.test.com/:developer_key_id/tool_configuration'

beforeEach(() => {
  axios.get = jest.fn()
})

afterEach(() => {
  errorHandler.mockReset()
  axios.get.mockRestore()
})

describe('fetchToolConfiguration', () => {
  describe('when the request is a success', () => {
    beforeEach(() => {
      axios.get.mockReturnValue({data: {tool_configuration: {}}})
      fetchToolConfiguration(clientId, showUrl, errorHandler)
    })

    it('does not call the error handler', () => {
      expect(errorHandler).not.toHaveBeenCalled()
    })

    it('makes a request to the correct endpoint', () => {
      expect(axios.get).toHaveBeenCalledWith('https://www.test.com/10000000009/tool_configuration')
    })
  })

  describe('when the request is not a success', () => {
    beforeEach(() => {
      axios.get.mockImplementation(() => {
        throw new Error()
      })
      fetchToolConfiguration(clientId, showUrl, errorHandler)
    })

    it('calls the error handler', () => {
      expect(errorHandler).toHaveBeenCalled()
    })
  })
})
