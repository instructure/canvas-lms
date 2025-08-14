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
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

describe('bulkFetchUserTags', () => {
  const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('calls the correct endpoint and returns the user tags mapping', async () => {
    const courseId = 42
    const userIds = [1, 2, 3]
    const apiResponse = {
      json: {
        1: [5, 6],
        2: [7],
        3: [],
      },
    }
    mockDoFetchApi.mockResolvedValueOnce(apiResponse as any)

    const result = await bulkFetchUserTags(courseId, userIds)

    expect(doFetchApi).toHaveBeenCalledWith({
      path: `/api/v1/courses/${courseId}/bulk_user_tags`,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      params: {
        user_ids: userIds.map(id => id.toString()),
      },
    })
    expect(result).toEqual(apiResponse.json)
  })

  it('throws if response.json is missing', async () => {
    mockDoFetchApi.mockResolvedValueOnce({} as any)
    await expect(bulkFetchUserTags(1, [2])).rejects.toThrow('Failed to bulk fetch user tags')
  })
})

describe('bulkDeleteGroupMemberships', () => {
  const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('calls the correct endpoint and returns the raw response', async () => {
    const groupId = 10
    const userIds = [1, 2, 3]
    const apiResponse = {json: {deleted_user_ids: [1, 2], unauthorized_user_ids: [3]}}
    mockDoFetchApi.mockResolvedValueOnce(apiResponse as any)

    const result = await bulkDeleteGroupMemberships(groupId, userIds)

    expect(doFetchApi).toHaveBeenCalledWith({
      path: `/api/v1/groups/${groupId}/users`,
      method: 'DELETE',
      params: {
        user_ids: userIds.map(id => id.toString()),
      },
    })
    expect(result).toBe(apiResponse)
  })

  it('returns the error if the API call fails', async () => {
    const error = new Error('Network error')
    mockDoFetchApi.mockRejectedValueOnce(error)
    const result = await bulkDeleteGroupMemberships(5, [7, 8])
    expect(result).toBe(error)
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
