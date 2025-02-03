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
import type {DifferentiationTagCategory} from '../types'

export const useDifferentiationTagSet = (
  differentiationTagSetId: number | undefined,
  includeDifferentiationTags?: boolean,
) => {
  return useQuery<DifferentiationTagCategory, Error>({
    queryKey: ['differentiationTagSet', differentiationTagSetId, includeDifferentiationTags],
    queryFn: async () => {
      if (!differentiationTagSetId) throw new Error('Missing category ID')

      const response = await doFetchApi<DifferentiationTagCategory>({
        path: `/api/v1/group_categories/${differentiationTagSetId}`,
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        params: {
          ...(includeDifferentiationTags && {'includes[]': 'groups'}),
        },
      })

      if (!response.json) throw new Error('Failed to fetch tag set')
      return response.json
    },
    enabled: !!differentiationTagSetId,
    staleTime: QUERY_STALE_TIME,
  })
}
