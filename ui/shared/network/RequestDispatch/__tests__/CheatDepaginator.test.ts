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

import {setupServer} from 'msw/node'
import cheaterDepaginate from '../CheatDepaginator'

describe('Shared > Network > CheatDepaginator', () => {
  const TEST_URL = 'http://localhost/example'
  const server = setupServer()

  let dispatch: any

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    dispatch = {
      _getJSON: vi.fn(),
    }
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  afterAll(() => {
    server.close()
  })

  it('passes headers to dispatch._getJSON', async () => {
    const customHeaders = {'X-Custom-Header': 'test-value'}
    const mockResponse = {
      data: [{example: true}],
      xhr: {getResponseHeader: () => null},
    }

    dispatch._getJSON.mockResolvedValue(mockResponse)

    await cheaterDepaginate(
      TEST_URL,
      {param: 'value'},
      () => {},
      () => {},
      dispatch,
      customHeaders,
    )

    expect(dispatch._getJSON).toHaveBeenCalledWith(TEST_URL, {param: 'value'}, customHeaders)
  })

  it('works without headers parameter', async () => {
    const mockResponse = {
      data: [{example: true}],
      xhr: {getResponseHeader: () => null},
    }

    dispatch._getJSON.mockResolvedValue(mockResponse)

    await cheaterDepaginate(
      TEST_URL,
      {param: 'value'},
      () => {},
      () => {},
      dispatch,
    )

    expect(dispatch._getJSON).toHaveBeenCalledWith(TEST_URL, {param: 'value'}, undefined)
  })
})
