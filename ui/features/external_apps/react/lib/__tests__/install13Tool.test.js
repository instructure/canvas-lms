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
import install13Tool from '../install13Tool'

const clientId = 10000000009
const createUrl = 'https://www.test.com/accounts/1/tool_configuration'

beforeEach(() => {
  axios.post = jest.fn()
  axios.post.mockReturnValue({data: {}})
})

afterEach(() => {
  axios.post.mockRestore()
})

describe('fetchToolConfiguration', () => {
  it('post the client id to the create url', () => {
    install13Tool(clientId, createUrl)
    expect(axios.post).toHaveBeenCalledWith(createUrl, {client_id: clientId})
  })

  it('post the client id and verify_uniqueness if true to the create url', () => {
    install13Tool(clientId, createUrl, true)
    expect(axios.post).toHaveBeenCalledWith(createUrl, {
      client_id: clientId,
      external_tool: {verify_uniqueness: true},
    })
  })
})
