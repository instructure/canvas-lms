/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {renderHook} from '@testing-library/react-hooks'
import {useAUPContent} from '../useAUPContent'

jest.mock('@canvas/do-fetch-api-effect')

const mockApiResponse = {content: '<p>Test Acceptable Use Policy Content</p>'}

describe('useAUPContent', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('initializes with loading set to true and error to false', () => {
    const {result} = renderHook(() => useAUPContent())
    expect(result.current.loading).toBe(true)
    expect(result.current.error).toBe(false)
    expect(result.current.content).toBe(null)
  })

  it('fetches content successfully and updates content and loading states', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: mockApiResponse,
      response: {ok: true},
    })
    const {result, waitForNextUpdate} = renderHook(() => useAUPContent())
    await waitForNextUpdate()
    expect(result.current.loading).toBe(false)
    expect(result.current.error).toBe(false)
    expect(result.current.content).toBe(mockApiResponse.content)
  })

  it('sets error to true if the API request fails', async () => {
    ;(doFetchApi as jest.Mock).mockRejectedValueOnce(new Error('API error'))
    const {result, waitForNextUpdate} = renderHook(() => useAUPContent())
    await waitForNextUpdate()
    expect(result.current.loading).toBe(false)
    expect(result.current.error).toBe(true)
    expect(result.current.content).toBe(null)
  })

  it('handles null content without setting error when response is ok', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: {content: null},
      response: {ok: true},
    })
    const {result, waitForNextUpdate} = renderHook(() => useAUPContent())
    await waitForNextUpdate()
    expect(result.current.loading).toBe(false)
    expect(result.current.error).toBe(false)
    expect(result.current.content).toBe(null)
  })
})
