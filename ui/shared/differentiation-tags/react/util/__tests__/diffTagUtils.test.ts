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

import {bulkFetchUserTags, bulkDeleteGroupMemberships, getCommonTagIds} from '../diffTagUtils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('bulkFetchUserTags', () => {
  let lastCapturedRequest: {path: string; params?: Record<string, string[]>} | null = null

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    lastCapturedRequest = null
    vi.clearAllMocks()
  })

  afterEach(() => server.resetHandlers())

  it('calls the correct endpoint and returns the user tags mapping', async () => {
    const courseId = 42
    const userIds = [1, 2, 3]
    const responseData = {
      1: [5, 6],
      2: [7],
      3: [],
    }

    server.use(
      http.get('/api/v1/courses/:courseId/bulk_user_tags', ({request, params}) => {
        const url = new URL(request.url)
        lastCapturedRequest = {
          path: url.pathname,
          params: {user_ids: url.searchParams.getAll('user_ids[]')},
        }
        return HttpResponse.json(responseData)
      }),
    )

    const result = await bulkFetchUserTags(courseId, userIds)

    expect(lastCapturedRequest).not.toBeNull()
    expect(lastCapturedRequest!.path).toBe(`/api/v1/courses/${courseId}/bulk_user_tags`)
    expect(lastCapturedRequest!.params?.user_ids).toEqual(['1', '2', '3'])
    expect(result).toEqual(responseData)
  })

  it('throws if response.json is missing', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/bulk_user_tags', () => {
        return new HttpResponse(null, {status: 204})
      }),
    )
    await expect(bulkFetchUserTags(1, [2])).rejects.toThrow('Failed to bulk fetch user tags')
  })
})

describe('bulkDeleteGroupMemberships', () => {
  let lastCapturedRequest: {path: string; method: string; params?: Record<string, string[]>} | null =
    null

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    lastCapturedRequest = null
    vi.clearAllMocks()
  })

  afterEach(() => server.resetHandlers())

  it('calls the correct endpoint and returns the raw response', async () => {
    const groupId = 10
    const userIds = [1, 2, 3]
    const responseData = {deleted_user_ids: [1, 2], unauthorized_user_ids: [3]}

    server.use(
      http.delete('/api/v1/groups/:groupId/users', ({request}) => {
        const url = new URL(request.url)
        lastCapturedRequest = {
          path: url.pathname,
          method: 'DELETE',
          params: {user_ids: url.searchParams.getAll('user_ids[]')},
        }
        return HttpResponse.json(responseData)
      }),
    )

    const result = await bulkDeleteGroupMemberships(groupId, userIds)

    expect(lastCapturedRequest).not.toBeNull()
    expect(lastCapturedRequest!.path).toBe(`/api/v1/groups/${groupId}/users`)
    expect(lastCapturedRequest!.method).toBe('DELETE')
    expect(lastCapturedRequest!.params?.user_ids).toEqual(['1', '2', '3'])
    expect(result).toEqual(expect.objectContaining({json: responseData}))
  })

  it('returns the error if the API call fails', async () => {
    server.use(http.delete('/api/v1/groups/:groupId/users', () => HttpResponse.error()))
    const result = await bulkDeleteGroupMemberships(5, [7, 8])
    expect(result).toBeInstanceOf(Error)
  })
})

describe('getCommonTagIds', () => {
  it('returns an empty set if users array is empty', () => {
    const result = getCommonTagIds([], {1: [1, 2], 2: [2, 3]})
    expect(result).toEqual(new Set())
  })

  it('returns all tags for a single user', () => {
    const result = getCommonTagIds([1], {1: [1, 2, 3]})
    expect(result).toEqual(new Set([1, 2, 3]))
  })

  it('returns only the common tags for multiple users', () => {
    const userTags = {
      1: [1, 2, 3, 4],
      2: [2, 3, 4, 5],
      3: [0, 2, 3, 4, 6],
    }
    const result = getCommonTagIds([1, 2, 3], userTags)
    expect(result).toEqual(new Set([2, 3, 4]))
  })

  it('returns an empty set if there are no common tags', () => {
    const userTags = {
      1: [1, 2],
      2: [3, 4],
      3: [5, 6],
    }
    const result = getCommonTagIds([1, 2, 3], userTags)
    expect(result).toEqual(new Set())
  })

  it('handles missing user IDs in userTags gracefully', () => {
    const userTags = {
      1: [1, 2],
      2: [2, 3],
    }
    const result = getCommonTagIds([1, 2, 3], userTags)
    expect(result).toEqual(new Set())
  })
})
