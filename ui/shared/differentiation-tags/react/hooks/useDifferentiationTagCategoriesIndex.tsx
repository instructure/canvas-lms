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
import {QUERY_STALE_TIME} from '../util/constants'
import {DifferentiationTagCategory} from '../types'

export const useDifferentiationTagCategoriesIndex = (
  courseId: number,
  includeDifferentiationTags: boolean = false,
) => {
  const fetchDifTagCategories = async () => {
    const response = await doFetchApi<Array<{id: number; name: string}>>({
      path: `/api/v1/courses/${courseId}/group_categories`,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      params: {
        collaboration_state: 'non_collaborative',
        ...(includeDifferentiationTags && {'includes[]': 'groups'}),
      },
    })

    if (!response.json) {
      throw new Error('Failed to fetch differentiation tag categories')
    }

    return response.json.map(
      (item): DifferentiationTagCategory => ({
        id: item.id,
        name: item.name,
      }),
    )
  }

  return useQuery<DifferentiationTagCategory[], Error>({
    queryKey: ['differentiationTagCategories', courseId, includeDifferentiationTags],
    queryFn: fetchDifTagCategories,
    enabled: !!courseId,
    staleTime: QUERY_STALE_TIME,
  })
}
