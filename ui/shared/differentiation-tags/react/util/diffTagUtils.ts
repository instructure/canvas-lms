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

import doFetchApi from '@canvas/do-fetch-api-effect'

/**
 * Bulk fetch user tags for a list of user IDs.
 * Calls the bulk_user_tags action in user_tags_controller.rb.
 *
 * @param courseId - The course ID
 * @param userIds - Array of user IDs to fetch tags for
 * @returns A record mapping user IDs to their tags
 */
export const bulkFetchUserTags = async (courseId: number, userIds: number[]) => {
  const response = await doFetchApi<Record<number, number[]>>({
    path: `/api/v1/courses/${courseId}/bulk_user_tags`,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    params: {
      user_ids: userIds.map(id => id.toString()),
    },
  })

  if (!response.json) {
    throw new Error('Failed to bulk fetch user tags')
  }
  return response.json
}

/**
 * Bulk delete group memberships (remove users from a group/tag).
 * Calls the destroy action in group_memberships_controller.rb.
 *
 * @param groupId - The group/tag ID
 * @param userIds - Array of user IDs to remove
 * @returns Raw response from the API
 */
export async function bulkDeleteGroupMemberships(groupId: number, userIds: number[]): Promise<any> {
  const url = `/api/v1/groups/${groupId}/users`
  const params: Record<string, string[]> = {
    user_ids: userIds.map(id => id.toString()),
  }

  try {
    const response = await doFetchApi({
      path: url,
      method: 'DELETE',
      params,
    })
    return response
  } catch (error) {
    return error
  }
}

export const getCommonTagIds = (
  users: number[],
  userTags: Record<number, number[]>,
): Set<number> => {
  return users.length
    ? users
        .map(userId => new Set(userTags[userId]))
        .reduce((a, b) => new Set([...a].filter(x => b.has(x))))
    : new Set()
}
