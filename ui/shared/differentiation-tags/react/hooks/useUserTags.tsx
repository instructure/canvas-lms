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
import {useQuery} from '@tanstack/react-query'
import {UserTags} from '../types'

export const useUserTags = (
  courseId: number,
  userId: number,
) => {
  const fetchUserTags= async () => {
    const response = await doFetchApi<Array<{id: number; name: string; group_category_name: string;}>>({
      path: `/api/v1/courses/${courseId}/groups`,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      params: {
        collaboration_state: 'non_collaborative',
        user_id: userId,
      },
    })

    if (!response.json) {
      throw new Error('Failed to fetch user tags')
    }

    return response.json.map(
      (item): UserTags => ({
        id: item.id,
        name: item.name,
        groupCategoryName: item.group_category_name,
      }),
    )
  }

  return useQuery<UserTags[], Error>({
    queryKey: ['userDifferentiationTags', courseId, userId],
    queryFn: fetchUserTags,
    enabled: !!courseId && !!userId,
    refetchOnMount: 'always',

  })
}
