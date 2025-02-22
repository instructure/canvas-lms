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
import {DifferentiationTagCategory, DifferentiationTagGroup} from '../types'

interface UseDifferentiationTagCategoriesOptions {
  includeDifferentiationTags?: boolean
  enabled?: boolean
}

export const useDifferentiationTagCategoriesIndex = (
  courseId: number,
  options: UseDifferentiationTagCategoriesOptions = {},
) => {
  const hasValidCourseId = !isNaN(courseId)
  const {includeDifferentiationTags = false, enabled = true} = options

  const fetchDifTagCategories = async () => {
    const response = await doFetchApi<
      Array<{id: number; name: string; groups: DifferentiationTagGroup[]}>
    >({
      path: `/api/v1/courses/${courseId}/group_categories`,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      params: {
        collaboration_state: 'non_collaborative',
        per_page: 60,
        ...(includeDifferentiationTags && {'includes[]': 'groups'}),
      },
    })

    return (response.json || []).map(
      (item): DifferentiationTagCategory => ({
        id: item.id,
        name: item.name,
        groups: item.groups || [],
      }),
    )
  }

  return useQuery<DifferentiationTagCategory[], Error>({
    queryKey: ['differentiationTagCategories', Number(courseId), includeDifferentiationTags],
    queryFn: fetchDifTagCategories,
    enabled: hasValidCourseId && enabled,
    staleTime: QUERY_STALE_TIME,
    retry: (failureCount, error) => {
      if (error.message.includes('404') || !hasValidCourseId) return false
      return failureCount < 3
    },
  })
}
